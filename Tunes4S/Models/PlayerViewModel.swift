import Foundation
import Combine
import SwiftUI
import AppKit
import AVFoundation
import ID3TagEditor

/// ViewModel for the main music player functionality
class PlayerViewModel: ObservableObject {
    // Published properties for SwiftUI binding
    @Published var songs: [Song] = []
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var duration: Double = 1.0
    @Published var volume: Float = 0.5
    @Published var isShuffle = false
    @Published var isRepeat = false
    @Published var gains: [Float] = Array(repeating: 0, count: 10)

    // Dependencies
    private let internalAudioService: AudioService
    private var cancellables = Set<AnyCancellable>()

    // Loading state
    @Published var isLoading = false

    init(internalAudioService: AudioService = AudioService()) {
        self.internalAudioService = internalAudioService
        setupAudioServiceBindings()
        loadDemoSong()
    }

    private func setupAudioServiceBindings() {
        // Bind audio service state to view model
        internalAudioService.$currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$progress)

        internalAudioService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)

        internalAudioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        internalAudioService.$volume
            .receive(on: DispatchQueue.main)
            .assign(to: &$volume)
    }

    // MARK: - Playback Controls

    func togglePlay() {
        guard let song = currentSong else { return }
        if isPlaying {
            internalAudioService.stop()
        } else {
            internalAudioService.play(song: song)
        }
    }

    func playSong(_ song: Song) {
        currentSong = song
        internalAudioService.stop()
        internalAudioService.play(song: song)
    }

    func stop() {
        internalAudioService.stop()
        progress = 0
    }

    func playNext() {
        guard let current = currentSong,
              let currentIndex = songs.firstIndex(where: { $0.id == current.id }) else { return }

        let nextIndex = getNextSongIndex(from: currentIndex)
        if let nextSong = songs[safe: nextIndex] {
            currentSong = nextSong
            playSong(nextSong)
        }
    }

    func playPrevious() {
        guard let current = currentSong,
              let currentIndex = songs.firstIndex(where: { $0.id == current.id }) else { return }

        let previousIndex = getPreviousSongIndex(from: currentIndex)
        if let previousSong = songs[safe: previousIndex] {
            currentSong = previousSong
            playSong(previousSong)
        }
    }

    private func getNextSongIndex(from currentIndex: Int) -> Int {
        if isShuffle {
            return Int.random(in: 0..<songs.count)
        } else {
            return (currentIndex + 1) % songs.count
        }
    }

    private func getPreviousSongIndex(from currentIndex: Int) -> Int {
        if isShuffle {
            return Int.random(in: 0..<songs.count)
        } else {
            return (currentIndex - 1 + songs.count) % songs.count
        }
    }

    // MARK: - Library Management

    func loadDemoSong() {
        // Create a demo song (in a real app this would come from file system or API)
        let demoSong = Song(
            id: 0,
            title: "Demo Song",
            album: "Tunes4S Demo",
            artist: "Winamp Classic",
            file: "demo.mp3",
            songImage: nil,
            duration: 180
        )
        songs.append(demoSong)
        currentSong = demoSong
    }

    func addSong(_ song: Song) {
        songs.append(song)
    }

    func removeSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        if currentSong?.id == song.id {
            stop()
            currentSong = songs.first
        }
    }

    func seekTo(_ time: Double) {
        internalAudioService.seek(to: time)
    }

    // MARK: - Audio Settings

    func setEqualizerBand(_ gain: Float, band: Int) {
        gains[band] = gain
        internalAudioService.setGain(gain, forBandAt: band)
    }

    func applyEqualizerPreset(_ preset: EqualizerPreset) {
        gains = preset.gains
        for i in 0..<preset.gains.count {
            internalAudioService.setGain(preset.gains[i], forBandAt: i)
        }
    }

    // MARK: - Song Information

    var currentSongTitle: String {
        currentSong?.title ?? "No Song Selected"
    }

    var currentSongArtist: String {
        currentSong?.artist ?? ""
    }

    var currentTimeFormatted: String {
        formatTime(progress)
    }

    var remainingTimeFormatted: String {
        formatTime(max(duration - progress, 0))
    }

    var totalTimeFormatted: String {
        formatTime(duration)
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func handleCurrentSongChange() {
        if let song = currentSong {
            playSong(song)
        }
    }

    // MARK: - Public Accessors

    /// Public accessor for AudioService
    public var audioService: AudioService {
        internalAudioService
    }

    /// Volume binding that goes directly to AudioService
    public var volumeBinding: Binding<Float> {
        Binding(
            get: { self.internalAudioService.volume },
            set: { self.internalAudioService.volume = $0 }
        )
    }

    // MARK: - File Management

    func importFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            let fm = FileManager.default
            songs.removeAll()

            if let enumerator = fm.enumerator(
                at: url, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants])
            {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "mp3" {
                        if let song = readMp3(path: fileURL.path) {
                            songs.append(song)
                        }
                    }
                }
            }

            if !songs.isEmpty {
                currentSong = songs[0]
            }
        }
    }

    private func readMp3(path: String) -> Song? {
        let song = Song(
            id: songs.count,
            title: fileNameFromPath(path),
            album: "Unknown Album",
            artist: "Unknown Artist",
            file: path,
            songImage: nil
        )

        // Try to load MP3 metadata using ID3TagEditor if available
        let id3TagEditor = ID3TagEditor()
        do {
            if let id3Tag = try id3TagEditor.read(from: path) {
                // Try to extract basic metadata
                for (key, frame) in id3Tag.frames {
                    if let stringFrame = frame as? ID3FrameWithStringContent, !stringFrame.content.isEmpty {
                        let frameKeyString = String(describing: key)
                        switch frameKeyString {
                        case "title", "TIT2":
                            song.title = stringFrame.content
                        case "artist", "TPE1":
                            song.artist = stringFrame.content
                        case "album", "TALB":
                            song.album = stringFrame.content
                        default:
                            break
                        }
                    }
                    // Extract album art from attached pictures
                    else if let imageFrame = frame as? ID3FrameAttachedPicture {
                        song.songImage = imageFrame.picture
                        print("Successfully loaded album art for: \(song.title)")
                    }
                }
            }
        } catch {
            print("Failed to read MP3 metadata: \(error)")
        }

        // Get actual duration using AVAudioFile
        let fileURL = URL(fileURLWithPath: path)
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let sampleRate = audioFile.processingFormat.sampleRate
            let lengthInFrames = Double(audioFile.length)
            song.duration = lengthInFrames / sampleRate
        } catch {
            song.duration = 180.0  // Fallback duration
        }

        return song
    }

    private func fileNameFromPath(_ path: String) -> String {
        return (path as NSString).lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
