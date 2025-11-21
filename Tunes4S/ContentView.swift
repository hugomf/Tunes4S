import AVFoundation
import AVKit
import AppKit
import Foundation
import ID3TagEditor
import MediaPlayer
import SwiftUI

struct ContentView: View {
  var body: some View {
    WinampPlayerView()
  }
}

struct WinampPlayerView: View {
  @State private var songs: [Song] = []
  @State private var currentSong: Song?
  @StateObject private var audioService = AudioService()
  @State private var showPlaylist = false
  @State private var showEqualizer = false
  @State private var gains: [Float] = Array(repeating: 0, count: 10)
  @State private var progress: Double = 0.0
  @State private var duration: Double = 1.0
  @State private var isPlaying: Bool = false
  @State private var volume: Float = 0.8
  @State private var isShuffle: Bool = false
  @State private var isRepeat: Bool = false

  // Peak dots for spectrum analyzer (Winamp style)
  @State private var peakHeights: [Float] = Array(repeating: 0, count: 20)
  @State private var peakTimer: Timer?

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        // Title Bar
        WinampTitleBar(showPlaylist: $showPlaylist, showEqualizer: $showEqualizer)

        // Main Display Area
        WinampDisplay(
          currentSong: $currentSong, isPlaying: $isPlaying, progress: $progress,
          duration: $duration, audioService: audioService)

        // Visual Time Progress
        WinampVisualProgress(progress: $progress, duration: $duration, onSeek: seekToTime)

        // Control Buttons
        WinampControls(
          isPlaying: $isPlaying,
          togglePlay: togglePlay,
          playNext: playNextSong,
          playPrevious: playPreviousSong,
          stop: stopSong,
          importFolder: importFolder,
          isShuffle: $isShuffle,
          isRepeat: $isRepeat
        )

        // Volume Control
        WinampVolumeControl(volume: $volume, audioService: audioService)

        // Equalizer (shown when toggle is on)
        if showEqualizer {
          WinampEqualizer(gains: $gains)
            .onChange(of: gains) { newGains in
              for i in 0..<newGains.count {
                audioService.setGain(newGains[i], forBandAt: i)
              }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
      .frame(width: 275, height: showEqualizer ? 580 : 430)
      .background(WinampBackground())
      .overlay(
        RoundedRectangle(cornerRadius: 0)
          .stroke(Color.black, lineWidth: 2)
      )

      if showPlaylist {
        WinampPlaylist(
          songs: $songs,
          currentSong: $currentSong,
          showPlaylist: $showPlaylist,
          isPlaying: $isPlaying,
          onReadMp3: {},
          onAudioStop: {}
        )
        .frame(width: 275, height: 580)
        .transition(.move(edge: .trailing))
      }
    }
    .onChange(of: currentSong) { _ in
      playSong()
    }
    .onReceive(audioService.$currentTime) { newTime in
      progress = newTime
    }
    .onReceive(audioService.$duration) { newDuration in
      duration = newDuration
    }
    .onReceive(audioService.$isPlaying) { newIsPlaying in
      isPlaying = newIsPlaying
    }
    .onAppear {
      setupKeyboardShortcuts()
      loadDemoFile()
    }
  }

  func loadDemoFile() {
    let demoPath =
      Bundle.main.path(forResource: "winamp_llama_demo", ofType: "mp3") ?? FileManager.default
      .currentDirectoryPath + "/winamp_llama_demo.mp3"

    if FileManager.default.fileExists(atPath: demoPath) {
      if let demoSong = readMp3(path: demoPath, id: 0) {
        songs.insert(demoSong, at: 0)
        currentSong = demoSong
        print("✅ Loaded Winamp demo file!")
      }
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

      if let enumerator = fm.enumerator(
        at: url, includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants])
      {
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
    let song = Song(
      id: id, title: fileNameFromPath(path), album: "Unknown Album", artist: "Unknown Artist",
      file: path, songImage: nil)

    // Try to load MP3 metadata using ID3TagEditor if available
    let id3TagEditor = ID3TagEditor()
    do {
      if let id3Tag = try id3TagEditor.read(from: path) {
        // Print available frames for debugging
        print("Available frames: \(id3Tag.frames.count)")
        for (key, _) in id3Tag.frames {
          print("  Frame key: \(key)")
        }

        // Try to extract basic metadata by iterating through frames
        for (key, frame) in id3Tag.frames {
          if let stringFrame = frame as? ID3FrameWithStringContent, !stringFrame.content.isEmpty {
            // Check frame identifier - convert FrameName to rawValue string
            let frameKeyString = String(describing: key)
            switch frameKeyString {
            case "title":
              song.title = stringFrame.content
              print("✅ Loaded title from frame: \(stringFrame.content)")
            case "artist":
              song.artist = stringFrame.content
              print("✅ Loaded artist from frame: \(stringFrame.content)")
            case "album":
              song.album = stringFrame.content
              print("✅ Loaded album from frame: \(stringFrame.content)")
            case "TIT2":
              song.title = stringFrame.content
              print("✅ Loaded title from TIT2 frame: \(stringFrame.content)")
            case "TPE1":
              song.artist = stringFrame.content
              print("✅ Loaded artist from TPE1 frame: \(stringFrame.content)")
            case "TALB":
              song.album = stringFrame.content
              print("✅ Loaded album from TALB frame: \(stringFrame.content)")
            default:
              break
            }
          } else if let pictureFrame = frame as? ID3FrameAttachedPicture {
            let artworkData = pictureFrame.picture
            if !artworkData.isEmpty {
              song.songImage = artworkData
              print("✅ Loaded artwork from picture frame (size: \(artworkData.count) bytes)")
            }
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

  func fileNameFromPath(_ path: String) -> String {
    return (path as NSString).lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
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

  func stopSong() {
    audioService.stop()
    isPlaying = false
    progress = 0
  }

  func playNextSong() {
    guard let currentSong = currentSong,
      let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id })
    else { return }

    var nextIndex: Int
    if isShuffle {
      repeat {
        nextIndex = Int.random(in: 0..<songs.count)
      } while nextIndex == currentIndex && songs.count > 1
    } else {
      nextIndex = (currentIndex + 1) % songs.count
    }

    self.currentSong = songs[nextIndex]
  }

  func playPreviousSong() {
    guard let currentSong = currentSong,
      let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id })
    else { return }

    var previousIndex: Int
    if isShuffle {
      repeat {
        previousIndex = Int.random(in: 0..<songs.count)
      } while previousIndex == currentIndex && songs.count > 1
    } else {
      previousIndex = (currentIndex - 1 + songs.count) % songs.count
    }

    self.currentSong = songs[previousIndex]
  }

  private func playSong() {
    if isPlaying {
      audioService.stop()
      guard let song = currentSong else { return }
      audioService.play(song: song)
    }
  }

  private func seekToTime(_ time: Double) {
    audioService.seek(to: time)
  }

  private func setupKeyboardShortcuts() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      switch event.keyCode {
      case 49:  // Space bar
        togglePlay()
        return nil
      case 123:  // Left arrow
        playPreviousSong()
        return nil
      case 124:  // Right arrow
        playNextSong()
        return nil
      case 125:  // Down arrow
        stopSong()
        return nil
      default:
        return event
      }
    }
  }

  // Peak dot management (Winamp-style bouncing peaks)
  private func startPeakDecay() {
    peakTimer?.invalidate()
    peakTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
      for i in 0..<self.peakHeights.count {
        self.peakHeights[i] = max(0.0, self.peakHeights[i] - 0.05)  // Decay by 0.05 per tick
      }
    }
  }

  private func stopPeakDecay() {
    peakTimer?.invalidate()
    peakTimer = nil
    peakHeights = Array(repeating: 0.0, count: 20)  // Reset peaks when stopped
  }

  private func updatePeakHeights(with spectrumData: [Float]) {
    // Update peak heights when new spectrum data arrives
    for i in 0..<spectrumData.count {
      let binValue = spectrumData[i]
      if binValue > peakHeights[i] {
        peakHeights[i] = binValue  // Update peak if spectrum value is higher
      }
    }

    // Start peak decay if not already running and playing
    if isPlaying && peakTimer == nil {
      startPeakDecay()
    }
  }
}

// MARK: - Winamp Background
struct WinampBackground: View {
  var body: some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(hex: "3C5068"), location: 0),
        .init(color: Color(hex: "5A768E"), location: 0.5),
        .init(color: Color(hex: "3C5068"), location: 1),
      ]),
      startPoint: .top,
      endPoint: .bottom
    )
  }
}

// MARK: - Title Bar
struct WinampTitleBar: View {
  @Binding var showPlaylist: Bool
  @Binding var showEqualizer: Bool
  @State private var dragOffset = CGSize.zero

  var body: some View {
    HStack(spacing: 0) {
      // Winamp Logo/Text
      Text("Winamp")
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(Color(hex: "00FF00"))
        .padding(.leading, 8)

      Spacer()

      // Window Control Buttons
      HStack(spacing: 2) {
        Button(action: { showPlaylist.toggle() }) {
          Text("PL")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 12)
            .background(Color(hex: "2A2A2A"))
            .overlay(Rectangle().stroke(Color(hex: "666666"), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())

        Button(action: { showEqualizer.toggle() }) {
          Text("EQ")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 12)
            .background(Color(hex: "2A2A2A"))
            .overlay(Rectangle().stroke(Color(hex: "666666"), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
      }
      .padding(.trailing, 8)
    }
    .frame(height: 14)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color(hex: "1E3A52"), Color(hex: "2B4A62")]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .overlay(
      Rectangle()
        .stroke(Color.black.opacity(0.5), lineWidth: 1)
    )
    .gesture(
      DragGesture()
        .onChanged { value in
          if let window = NSApplication.shared.windows.first {
            dragOffset = value.translation
            window.setFrameOrigin(
              NSPoint(
                x: window.frame.origin.x + dragOffset.width,
                y: window.frame.origin.y - dragOffset.height
              )
            )
          }
        }
    )
  }
}

class SpectrumViewModel: ObservableObject {
  var spectrumData: [Float] = Array(repeating: 0, count: 20)
  var peakHeights: [Float] = Array(repeating: 0, count: 20)
  private var peakTimer: Timer?

  init() {
    startPeakDecay()
  }

  deinit {
    stopPeakDecay()
  }

  func updateSpectrum(_ newSpectrumData: [Float]) {
    spectrumData = newSpectrumData

    // Update peak heights when new spectrum data arrives
    for i in 0..<newSpectrumData.count {
      let binValue = newSpectrumData[i]
      if binValue > peakHeights[i] {
        peakHeights[i] = binValue  // Update peak if spectrum value is higher
      }
    }
  }

  private func startPeakDecay() {
    peakTimer?.invalidate()
    peakTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
      for i in 0..<self.peakHeights.count {
        self.peakHeights[i] = max(0.0, self.peakHeights[i] - 0.05)  // Decay by 0.05 per tick
      }
    }
  }

  private func stopPeakDecay() {
    peakTimer?.invalidate()
    peakTimer = nil
    peakHeights = Array(repeating: 0.0, count: 20)  // Reset peaks when stopped
  }
}

// MARK: - Main Display
struct WinampDisplay: View {
  @Binding var currentSong: Song?
  @Binding var isPlaying: Bool
  @Binding var progress: Double
  @Binding var duration: Double
  @ObservedObject var audioService: AudioService
  @StateObject private var spectrumModel = SpectrumViewModel()

  var body: some View {
    VStack(spacing: 8) {
      // Top info bar (bitrate, khz, stereo)
      HStack(spacing: 4) {
        WinampLEDText(text: "128", width: 32, color: .green)
        WinampLEDText(text: "44", width: 24, color: .green)
        Rectangle()
          .fill(isPlaying ? Color(hex: "00FF00") : Color(hex: "003300"))
          .frame(width: 30, height: 12)
          .overlay(
            Text("STEREO")
              .font(.system(size: 6, weight: .bold))
              .foregroundColor(.black)
          )
        Spacer()
      }
      .padding(.horizontal, 6)
      .padding(.top, 8)

      // Song Title Display with Spectrum Analyzer
      HStack(spacing: 8) {
        // Left side with Album Art and Song Info
        VStack(alignment: .leading, spacing: 2) {
          // Album Art Thumbnail
          ZStack {
            Rectangle()
              .fill(Color.black)
              .frame(width: 50, height: 50)

            if let song = currentSong,
              let songImage = song.songImage,
              let nsImage = NSImage(data: songImage)
            {
              Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipped()
            } else {
              Image(systemName: "music.note")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "00FF00"))
            }
          }
          .overlay(Rectangle().stroke(Color(hex: "222222"), lineWidth: 1))

          // Song Info
          VStack(alignment: .leading, spacing: 2) {
            ScrollingText(text: currentSong?.title ?? "Winamp v2.95", isPlaying: isPlaying)

            Text(currentSong?.artist ?? "")
              .font(.system(size: 9))
              .foregroundColor(Color(hex: "AAAAAA"))
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        // Right side with Spectrum Analyzer and Time
        VStack(spacing: 4) {
          // LED Spectrum Analyzer (smaller version)
          WinampLEDSpectrumAnalyzer(
            isPlaying: $isPlaying,
            spectrumData: spectrumModel.spectrumData,
            peakHeights: spectrumModel.peakHeights,
            compact: true
          )
          .onReceive(audioService.$spectrumData) { newData in
            spectrumModel.updateSpectrum(newData)
          }

          // Time Display
          HStack(spacing: 8) {
            WinampTimeDisplay(time: progress)
            Spacer()
            WinampTimeDisplay(time: duration - progress, isRemaining: true)
          }
        }
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 4)
    }
    .frame(height: 120)
    .background(Color(hex: "2A2A2A"))
    .overlay(
      Rectangle()
        .stroke(Color(hex: "1A1A1A"), lineWidth: 1)
    )
  }
}

// MARK: - LED Spectrum Analyzer (Old LCD Style)
struct WinampLEDSpectrumAnalyzer: View {
  @Binding var isPlaying: Bool
  let spectrumData: [Float]
  let peakHeights: [Float]
  private let spectrumBins = 20
  private let verticalLeds = 16  // More vertical LED bars
  let compact: Bool

  init(isPlaying: Binding<Bool>, spectrumData: [Float], peakHeights: [Float], compact: Bool = false)
  {
    self._isPlaying = isPlaying
    self.spectrumData = spectrumData
    self.peakHeights = peakHeights
    self.compact = compact
  }

  var body: some View {
    ZStack {
      // Spectrum bars (background)
      VStack(spacing: 0.5) {
        ForEach(0..<verticalLeds, id: \.self) { row in
          HStack(spacing: 0.5) {
            ForEach(0..<spectrumBins, id: \.self) { column in
              RoundedRectangle(cornerRadius: 0.25)
                .fill(getLEDColor(for: row, column: column))
                .frame(width: compact ? 2 : 3, height: compact ? 2 : 3)
            }
          }
        }
      }

      // Peak dots (foreground) - white bouncing dots on top
      VStack(spacing: 0.5) {
        ForEach(0..<verticalLeds, id: \.self) { row in
          HStack(spacing: 0.5) {
            ForEach(0..<spectrumBins, id: \.self) { column in
              RoundedRectangle(cornerRadius: 0.25)
                .fill(getPeakColor(for: row, column: column))
                .frame(width: compact ? 2 : 3, height: compact ? 2 : 3)
            }
          }
        }
      }
    }
    .padding(.horizontal, 6)
  }

  private func getLEDColor(for row: Int, column: Int) -> Color {
    guard isPlaying else { return Color(hex: "001100") }  // Darker off color

    // Get the frequency bin value (0-1, linear)
    let binValue = column < spectrumData.count ? spectrumData[column] : 0.0

    // Convert bin value to LED intensity (0-verticalLeds bars depending on value)
    let ledIntensity = Int(binValue * Float(verticalLeds))

    // Row logic: higher frequencies (smaller row numbers) get more active LEDs
    // Reverse the row logic so bars grow upward from the bottom
    let reversedRowIndex = verticalLeds - 1 - row
    let isActive = reversedRowIndex < ledIntensity

    if !isActive {
      return Color(hex: "003300")
    }

    // Color based on row position (0-15) for gradient effect within columns
    // Classic Winamp: bottom = green, middle = yellow, top = red
    // row 0-7: top quarter, red
    // row 8-11: middle half, yellow
    // row 12-15: bottom quarter, green
    if row < 4 {
      // Top 25% of display: red when active (reaches max height)
      return Color(hex: "FF0000")
    } else if row < 10 {
      // Middle 50% of display: yellow when active (bars must reach 62.5%+ height)
      return Color(hex: "FFFF00")
    } else {
      // Bottom 25% of display: green when active (lower amplitude = green tones)
      return Color(hex: "00FF00")
    }
  }

  private func getPeakColor(for row: Int, column: Int) -> Color {
    guard isPlaying else { return Color.clear }  // No peaks when not playing

    // Get the peak height value (0-1, linear)
    let peakValue = column < peakHeights.count ? peakHeights[column] : 0.0

    // Convert peak value to LED position (which row should show the peak)
    let peakRow = Int(peakValue * Float(verticalLeds))

    // Row logic: higher frequencies get peaks at lower row numbers
    let reversedPeakRowIndex = verticalLeds - 1 - peakRow

    // Show white peak dot if this row is at the exact peak position
    if row == reversedPeakRowIndex && peakValue > 0.0 {
      return Color.white  // Winamp-style bouncing peak dot
    } else {
      return Color.clear  // Transparent (no peak here)
    }
  }
}

// MARK: - Visual Time Progress
struct WinampVisualProgress: View {
  @Binding var progress: Double
  @Binding var duration: Double
  var onSeek: (Double) -> Void
  @State private var isDragging = false
  @State private var dragProgress: Double = 0

  var body: some View {
    VStack(spacing: 4) {
      // Visual progress bar with dots
      HStack(spacing: 2) {
        ForEach(0..<50, id: \.self) { index in
          let progressRatio = (isDragging ? dragProgress : progress) / max(duration, 1)
          let isActive = Double(index) / 50.0 <= progressRatio

          Rectangle()
            .fill(isActive ? Color(hex: "00FF00") : Color(hex: "003300"))
            .frame(width: 4, height: 8)
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          isDragging = true
          let clampedX = max(0, min(value.location.x, 275))  // Approximate width
          dragProgress = (clampedX / 275) * duration
        }
        .onEnded { value in
          let clampedX = max(0, min(value.location.x, 275))
          let seekTime = (clampedX / 275) * duration
          onSeek(seekTime)
          isDragging = false
        }
    )
  }
}

// MARK: - LED Text Display
struct WinampLEDText: View {
  let text: String
  let width: CGFloat
  let color: Color

  var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .bold, design: .monospaced))
      .foregroundColor(color == .green ? Color(hex: "00FF00") : Color(hex: "FF6600"))
      .frame(width: width, height: 12)
      .background(Color.black)
      .overlay(Rectangle().stroke(Color(hex: "333333"), lineWidth: 1))
  }
}

// MARK: - Scrolling Text
struct ScrollingText: View {
  let text: String
  let isPlaying: Bool
  @State private var offset: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      Text(text + "  ***  ")
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .foregroundColor(Color(hex: "00FF00"))
        .offset(x: offset)
        .onAppear {
          if isPlaying {
            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
              offset = -200
            }
          }
        }
        .onChange(of: isPlaying) { playing in
          if playing {
            offset = geometry.size.width
            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
              offset = -200
            }
          } else {
            offset = 0
          }
        }
    }
    .frame(height: 16)
    .background(Color.black)
    .clipped()
  }
}

// MARK: - Time Display
struct WinampTimeDisplay: View {
  let time: Double
  let isRemaining: Bool

  init(time: Double, isRemaining: Bool = false) {
    self.time = time
    self.isRemaining = isRemaining
  }

  var body: some View {
    HStack(spacing: 1) {
      ForEach(Array(formatTime(time).enumerated()), id: \.offset) { index, char in
        Text(String(char))
          .font(.system(size: 16, weight: .bold, design: .monospaced))
          .foregroundColor(Color(hex: "00FF00"))
          .frame(width: 10, height: 18)
      }
    }
    .padding(2)
    .background(Color.black)
    .overlay(Rectangle().stroke(Color(hex: "1A1A1A"), lineWidth: 1))
  }

  private func formatTime(_ time: Double) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: isRemaining ? "-%d:%02d" : "%d:%02d", minutes, seconds)
  }
}

// MARK: - Control Buttons
struct WinampControls: View {
  @Binding var isPlaying: Bool
  var togglePlay: () -> Void
  var playNext: () -> Void
  var playPrevious: () -> Void
  var stop: () -> Void
  var importFolder: () -> Void
  @Binding var isShuffle: Bool
  @Binding var isRepeat: Bool

  var body: some View {
    VStack(spacing: 6) {
      // Main playback controls
      HStack(spacing: 4) {
        WinampButton(icon: "backward.end.fill", size: 32, action: playPrevious)
        WinampButton(icon: isPlaying ? "pause.fill" : "play.fill", size: 36, action: togglePlay)
        WinampButton(icon: "stop.fill", size: 32, action: stop)
        WinampButton(icon: "forward.end.fill", size: 32, action: playNext)
        WinampButton(icon: "eject.fill", size: 28, action: importFolder)
      }
      .padding(.horizontal, 16)

      // Shuffle/Repeat controls
      HStack(spacing: 8) {
        WinampToggleButton(
          icon: "shuffle",
          isActive: isShuffle,
          action: { isShuffle.toggle() }
        )

        WinampToggleButton(
          icon: "repeat",
          isActive: isRepeat,
          action: { isRepeat.toggle() }
        )
      }
      .padding(.horizontal, 16)
    }
    .padding(.vertical, 8)
  }
}

// MARK: - Winamp Button
struct WinampButton: View {
  let icon: String
  let size: CGFloat
  let action: () -> Void
  @State private var isPressed = false

  var body: some View {
    Button(action: action) {
      ZStack {
        // Button background with more realistic gradient
        RoundedRectangle(cornerRadius: 2)
          .fill(
            LinearGradient(
              gradient: Gradient(
                colors: isPressed
                  ? [
                    Color(hex: "4A6A82"),
                    Color(hex: "5A7A92"),
                  ]
                  : [
                    Color(hex: "5A7A92"),
                    Color(hex: "4A6A82"),
                  ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 2)
              .stroke(Color(hex: "2A4A62"), lineWidth: 1)
          )

        Image(systemName: icon)
          .font(.system(size: size * 0.4))
          .foregroundColor(Color(hex: "00FF00"))
      }
      .frame(width: size, height: size)
    }
    .buttonStyle(PlainButtonStyle())
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in isPressed = false }
    )
  }
}

// MARK: - Toggle Button
struct WinampToggleButton: View {
  let icon: String
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        RoundedRectangle(cornerRadius: 2)
          .fill(
            LinearGradient(
              gradient: Gradient(
                colors: isActive
                  ? [
                    Color(hex: "4A6A82"),
                    Color(hex: "5A7A92"),
                  ]
                  : [
                    Color(hex: "2A2A2A"),
                    Color(hex: "3A3A3A"),
                  ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 2)
              .stroke(Color(hex: "2A4A62"), lineWidth: 1)
          )

        Image(systemName: icon)
          .font(.system(size: 12))
          .foregroundColor(isActive ? Color(hex: "00FF00") : Color(hex: "666666"))
      }
      .frame(width: 28, height: 16)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Volume Control (Horizontal)
struct WinampVolumeControl: View {
  @Binding var volume: Float
  @ObservedObject var audioService: AudioService
  @State private var isDragging = false

  var body: some View {
    VStack(spacing: 4) {
      Text("VOL")
        .font(.system(size: 9, weight: .bold))
        .foregroundColor(Color(hex: "00FF00"))

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Fixed track background with dark green and glow
          RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: "002200"))  // Dark green background
            .frame(height: 16)
            .overlay(
              RoundedRectangle(cornerRadius: 2)
                .fill(Color.green.opacity(0.3))  // Subtle green glow
                .blur(radius: 2)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: "0A0A0A"), lineWidth: 1)
            )

          // Volume level that transitions color based on level
          Rectangle()
            .fill(volumeBarColor)
            .frame(width: CGFloat(volume) * geometry.size.width, height: 16)
            .overlay(
              Rectangle()
                .fill(volumeBarColor.opacity(0.6))
                .blur(radius: 2)
                .frame(width: CGFloat(volume) * geometry.size.width + 4, height: 16)
            )

          // Handle
          RoundedRectangle(cornerRadius: 2)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color(hex: "EEEEEE"),
                  Color(hex: "999999"),
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: 10, height: 12)
            .position(x: CGFloat(volume) * geometry.size.width, y: 8)
            .gesture(
              DragGesture()
                .onChanged { value in
                  let newX = max(0, min(value.location.x, geometry.size.width))
                  volume = Float(newX / geometry.size.width)
                  audioService.setVolume(volume)
                }
            )
        }
      }
      .frame(height: 16)

      Text("\(Int(volume * 100))%")
        .font(.system(size: 7, weight: .bold))
        .foregroundColor(Color(hex: "00FF00"))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  private var volumeBarColor: Color {
    // Smooth gradient transitions as requested:
    // 0-50%: Green to green-with-yellow-tint
    // 50-75%: Green-to-yellow transition
    // 75-80%: Full yellow to yellow-with-red-tint
    // 80-95%: Yellow-to-red transition
    // 95-100%: Full red

    if volume < 0.5 {
      // 0-50%: Pure green
      return Color(hex: "00FF00")
    } else if volume < 0.75 {
      // 50-75%: Green to yellow transition
      let transitionProgress = (volume - 0.5) / 0.25  // 0 to 1 over 50-75%
      let green = UInt8(255 - transitionProgress * 0)  // Green stays at 255
      let red = UInt8(transitionProgress * 255)  // Red increases from 0 to 255
      let blue = UInt8(transitionProgress * 0)  // Blue stays at 0
      return Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    } else if volume < 0.8 {
      // 75-80%: Full yellow
      return Color(hex: "FFFF00")
    } else if volume < 0.95 {
      // 80-95%: Yellow to red transition
      let transitionProgress = (volume - 0.8) / 0.15  // 0 to 1 over 80-95%
      let green = UInt8(255 - transitionProgress * 255)  // Green decreases from 255 to 0
      let red = UInt8(255)  // Red stays at 255
      let blue = UInt8(transitionProgress * 0)  // Blue stays at 0
      return Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    } else {
      // 95-100%: Full red
      return Color(hex: "FF0000")
    }
  }
}

// MARK: - Equalizer
struct WinampEqualizer: View {
  @Binding var gains: [Float]
  let frequencies: [String] = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
  @State private var selectedPreset: EqualizerPreset = .normal

  var body: some View {
    VStack(spacing: 4) {
      // EQ Title
      HStack {
        Text("EQUALIZER")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(Color(hex: "00FF00"))

        Menu(selectedPreset.rawValue) {
          ForEach(EqualizerPreset.allCases, id: \.self) { preset in
            Button(preset.rawValue) {
              selectedPreset = preset
              applyPreset(preset)
            }
          }
        }
        .font(.system(size: 8))
        .foregroundColor(Color(hex: "00FF00"))
        .frame(width: 60)

        Spacer()

        Text("PREAMP")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(Color(hex: "00FF00"))
      }
      .padding(.horizontal, 12)
      .padding(.top, 4)

      // EQ Sliders
      HStack(spacing: 6) {
        ForEach(0..<gains.count, id: \.self) { index in
          VStack(spacing: 2) {
            // Slider Track
            ZStack(alignment: .center) {
              // Track background with color based on position
              let normalizedGain = (gains[index] + 12) / 24  // Normalize to 0-1
              let trackColor = trackColorForPosition(normalizedGain)

              RoundedRectangle(cornerRadius: 2)
                .fill(trackColor)
                .frame(width: 20, height: 140)
                .overlay(
                  RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: "0A0A0A"), lineWidth: 1)
                )
                .shadow(color: trackColor, radius: 4, x: 0, y: 0)

              // Center line
              Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 20, height: 1)

              // Slider handle - always gray
              let sliderY = 140 * (1 - CGFloat(normalizedGain))  // Calculate Y position

              RoundedRectangle(cornerRadius: 1)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(hex: "EEEEEE"),
                      Color(hex: "999999"),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
                )
                .frame(width: 18, height: 6)
                .position(x: 10, y: sliderY)
                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                .gesture(
                  DragGesture()
                    .onChanged { value in
                      let newY = max(0, min(value.location.y, 140))
                      let normalizedValue = 1 - (newY / 140)
                      gains[index] = Float(normalizedValue * 24 - 12)
                    }
                )
            }
            .frame(width: 20, height: 140)

            // Frequency label
            Text(frequencies[index])
              .font(.system(size: 7, weight: .bold))
              .foregroundColor(Color(hex: "00FF00"))
          }
        }
      }
    }
  }

  // Calculate track color based on position (0-1)
  private func trackColorForPosition(_ position: Float) -> Color {
    if position < 0.5 {
      // Green to Yellow transition (bottom to middle)
      let t = position * 2  // Scale to 0-1 range
      return Color(
        red: Double(t),  // Red increases from 0 to 1
        green: 1.0,  // Green stays at 1
        blue: 0.0  // Blue stays at 0
      )
    } else {
      // Yellow to Red transition (middle to top)
      let t = (position - 0.5) * 2  // Scale to 0-1 range
      return Color(
        red: 1.0,  // Red stays at 1
        green: Double(1.0 - t),  // Green decreases from 1 to 0
        blue: 0.0  // Blue stays at 0
      )
    }
  }

  private var eqTrackBackgroundColor: Color {
    // Get the overall EQ gain level for background (average of all gains)
    let averageGain = gains.reduce(0, +) / Float(gains.count)

    // Same logic as volume: -12 to +12 dB mapped to green-yellow-red transition
    if averageGain < 0 {
      // Negative gains = green
      let greenIntensity = Float(-(averageGain - 12)) / 24.0  // 0 to 1 as gain goes from -12 to 0
      return Color(red: Double(greenIntensity), green: Double(greenIntensity * 0.8), blue: 0)
    } else {
      // Positive gains = red
      let redIntensity = Float(averageGain / 12.0)  // 0 to 1 as gain goes from 0 to +12
      return Color(red: Double(redIntensity), green: Double(1 - redIntensity * 0.8), blue: 0)
    }
  }

  private func eqFillColor(for gain: Float) -> Color {
    // For the filled portion above/below the center line
    if gain < 0 {
      // Cuts = green
      let intensity = Float(-gain / 12.0)  // 0 to 1 as gain goes from 0 to -12
      return Color(red: Double(intensity), green: Double(intensity * 0.8), blue: 0)
    } else {
      // Boosts = red
      let intensity = Float(gain / 12.0)  // 0 to 1 as gain goes from 0 to +12
      return Color(red: Double(intensity), green: Double(1 - intensity * 0.8), blue: 0)
    }
  }

  private func applyPreset(_ preset: EqualizerPreset) {
    for i in 0..<gains.count {
      gains[i] = preset.gains[i]
    }
  }
}

// MARK: - Equalizer Presets
enum EqualizerPreset: String, CaseIterable {
  case normal = "Normal"
  case rock = "Rock"
  case pop = "Pop"
  case jazz = "Jazz"
  case classical = "Classical"
  case electronic = "Electronic"

  var gains: [Float] {
    switch self {
    case .normal:
      return [0, 0, 0, 0, 0, 0, 0, 0, 0]
    case .rock:
      return [5, 4, 3, 1, -1, 1, 3, 4, 5, 5]
    case .pop:
      return [-1, 2, 4, 4, 2, -1, -1, 0, 1, 1]
    case .jazz:
      return [4, 3, 1, 2, -2, -1, 1, 2, 3, 4]
    case .classical:
      return [5, 4, 3, 2, -2, -2, 0, 2, 3, 4]
    case .electronic:
      return [5, 4, 3, 0, -1, 1, 0, 1, 3, 5]
    }
  }
}
