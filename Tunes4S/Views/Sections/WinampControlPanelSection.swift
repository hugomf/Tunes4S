import SwiftUI

// MARK: - Control Panel Section
struct WinampControlPanelSection: View {
  @Binding var isPlaying: Bool
  var togglePlay: () -> Void
  var playNext: () -> Void
  var playPrevious: () -> Void
  var stop: () -> Void
  var importFolder: () -> Void
  @Binding var isShuffle: Bool
  @Binding var isRepeat: Bool
  @Binding var volume: Float
  @ObservedObject var audioService: AudioService

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

      // Volume Control
      WinampVolumeControl(volume: $volume, audioService: audioService)
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 8)
  }

}

// MARK: - Preview
#Preview {
  WinampControlPanelSection(
    isPlaying: .constant(true),
    togglePlay: {},
    playNext: {},
    playPrevious: {},
    stop: {},
    importFolder: {},
    isShuffle: .constant(false),
    isRepeat: .constant(true),
    volume: .constant(0.8),
    audioService: AudioService()
  )
}
