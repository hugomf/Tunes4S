//
//  ContentView.swift
//  PersonApp
//
//  Created by Hugo Martinez Fernandez on 07/06/22.
//

import SwiftUI
import MediaPlayer
import AVKit
import ID3TagEditor
import AVFoundation

struct ContentView: View {
    var body: some View {
        WinampPlayerView()
    }
}

struct WinampPlayerView: View {
    @State private var songs: [Song] = []
    @State private var searchText = ""
    @State private var currentSong: Song?
    @State private var isPlaying = false
    @StateObject private var audioService = AudioService()
    @State private var showPlaylist = false
    @State private var gains: [Float] = Array(repeating: 0, count: 10)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView(showPlaylist: $showPlaylist)
                DisplayView(currentSong: $currentSong)
                ControlsView(isPlaying: $isPlaying, togglePlay: togglePlay, playNext: playNextSong, playPrevious: playPreviousSong)
                EqualizerView(gains: $gains)
                    .onChange(of: gains) { newGains in
                        for i in 0..<newGains.count {
                            audioService.setGain(newGains[i], forBandAt: i)
                        }
                    }
                FooterView(importFolder: importFolder)
            }
            .frame(width: 350, height: 500)
            .background(Color(hex: "2c2c2c"))
            .cornerRadius(10)
            .shadow(radius: 10)

            if showPlaylist {
                PlaylistView(songs: $songs, currentSong: $currentSong, showPlaylist: $showPlaylist, isPlaying: $isPlaying)
                    .frame(width: 350, height: 500)
                    .background(Color(hex: "2c2c2c"))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom))
            }
        }
        .onChange(of: currentSong) { _ in
            playSong()
        }
    }

    func importFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            let fm = FileManager.default
            
            songs.removeAll()

            if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "mp3" {
                        if let song = readMp3(path: fileURL.path, id: songs.count) {
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

    func readMp3(path: String, id: Int) -> Song? {
        let id3TagEditor = ID3TagEditor()

        do {
            if let id3Tag = try id3TagEditor.read(from: path) {
                let tagContentReader = ID3TagContentReader(id3Tag: id3Tag)
                let title = tagContentReader.title() ?? "Unknown"
                let album = tagContentReader.album() ?? "Unknown Album"
                let songImage = tagContentReader.attachedPictures().first as? ID3FrameAttachedPicture

                return Song(
                    id: id,
                    title: title,
                    album: album,
                    file: path,
                    songImage: songImage
                )
            }
        } catch {
            print(error)
        }
        return nil
    }

    func togglePlay() {
        isPlaying.toggle()

        if isPlaying {
            guard let song = currentSong else { return }
            audioService.play(song: song)
        } else {
            audioService.stop()
        }
    }

    func playNextSong() {
        guard let currentSong = currentSong, let currentIndex = songs.firstIndex(of: currentSong) else { return }
        let nextIndex = (currentIndex + 1) % songs.count
        self.currentSong = songs[nextIndex]
        playSong()
    }

    func playPreviousSong() {
        guard let currentSong = currentSong, let currentIndex = songs.firstIndex(of: currentSong) else { return }
        let previousIndex = (currentIndex - 1 + songs.count) % songs.count
        self.currentSong = songs[previousIndex]
        playSong()
    }

    private func playSong() {
        if isPlaying {
            audioService.stop()
            guard let song = currentSong else { return }
            audioService.play(song: song)
        }
    }
}

struct HeaderView: View {
    @Binding var showPlaylist: Bool

    var body: some View {
        HStack {
            Text("WINAMP")
                .font(.custom("Helvetica Neue", size: 24))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "ffcc00"))
            Spacer()
            Button(action: {
                withAnimation {
                    showPlaylist.toggle()
                }
            }) {
                Image(systemName: "music.note.list")
                    .foregroundColor(Color(hex: "ffcc00"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "1c1c1c"))
    }
}

struct DisplayView: View {
    @Binding var currentSong: Song?

    var body: some View {
        VStack {
            Text(currentSong?.title ?? "No Song Playing")
                .foregroundColor(Color(hex: "ffcc00"))
                .padding()
            Text(currentSong?.album ?? "")
                .foregroundColor(Color(hex: "cccccc"))
        }
        .frame(height: 100)
    }
}

struct ControlsView: View {
    @Binding var isPlaying: Bool
    var togglePlay: () -> Void
    var playNext: () -> Void
    var playPrevious: () -> Void

    var body: some View {
        HStack {
            Button(action: playPrevious) {
                Image(systemName: "backward.fill")
            }
            Button(action: togglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: playNext) {
                Image(systemName: "forward.fill")
            }
        }
        .foregroundColor(Color(hex: "ffcc00"))
        .font(.system(size: 24))
        .padding()
    }
}

struct EqualizerView: View {
    @Binding var gains: [Float]
    let frequencies: [String] = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]

    var body: some View {
        VStack {
            Text("Equalizer").foregroundColor(Color(hex: "ffcc00"))
            HStack(spacing: 15) {
                ForEach(0..<gains.count, id: \.self) { index in
                    VStack(spacing: 5) {
                        Slider(value: $gains[index], in: -12...12, step: 0.1)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80)
                        Text(frequencies[index])
                            .foregroundColor(Color(hex: "cccccc"))
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(hex: "1c1c1c"))
        .frame(height: 150)
    }
}

struct PlaylistView: View {
    @Binding var songs: [Song]
    @Binding var currentSong: Song?
    @Binding var showPlaylist: Bool
    @Binding var isPlaying: Bool

    var body: some View {
        VStack {
            HStack {
                Text("Playlist")
                    .font(.custom("Helvetica Neue", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "ffcc00"))
                Spacer()
                Button(action: {
                    withAnimation {
                        showPlaylist = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(hex: "ffcc00"))
                }
            }
            .padding()
            .background(Color(hex: "1c1c1c"))

            List(songs) { song in
                Text(song.title)
                    .foregroundColor(currentSong?.id == song.id ? Color(hex: "ffcc00") : Color(hex: "cccccc"))
                    .onTapGesture {
                        currentSong = song
                        isPlaying = true
                    }
            }
            .background(Color(hex: "1c1c1c"))
        }
    }
}

struct FooterView: View {
    var importFolder: () -> Void

    var body: some View {
        Button(action: importFolder) {
            Text("Import Folder")
                .foregroundColor(Color(hex: "ffcc00"))
        }
        .padding()
        .background(Color(hex: "1c1c1c"))
    }
}

class AudioService: ObservableObject {
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 10)

    private let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.attach(eqNode)

        for i in 0..<eqNode.bands.count {
            eqNode.bands[i].frequency = frequencies[i]
            eqNode.bands[i].bypass = false
            eqNode.bands[i].filterType = .parametric
        }

        engine.connect(playerNode, to: eqNode, format: nil)
        engine.connect(eqNode, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func play(song: Song) {
        let fileURL = URL(fileURLWithPath: song.file)

        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            playerNode.scheduleFile(audioFile, at: nil)
            playerNode.play()
        } catch {
            print("Error playing song: \(error)")
        }
    }

    func stop() {
        playerNode.stop()
    }

    func setGain(_ gain: Float, forBandAt index: Int) {
        eqNode.bands[index].gain = gain
    }
}
