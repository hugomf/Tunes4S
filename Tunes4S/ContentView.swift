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

// MARK: - Preview
#Preview("Winamp Player") {
  ContentView()
}

struct WinampPlayerView: View {
  // Use ViewModels for state management
  @StateObject private var playerViewModel = PlayerViewModel()
  @StateObject private var equalizerViewModel = EqualizerViewModel()

  @State private var showPlaylist = false
  @State private var showEqualizer = false

  // Keep spectrum analyzer state in view (temporary - could be moved to ViewModel later)
  @State private var peakHeights: [Float] = Array(repeating: 0, count: 20)
  @State private var peakTimer: Timer?

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        // Title Bar
        WinampTitleBar(showPlaylist: $showPlaylist, showEqualizer: $showEqualizer)

        // Main Display Area - Using ViewModel data
        WinampDisplaySection(
          currentSong: $playerViewModel.currentSong,
          isPlaying: $playerViewModel.isPlaying,
          progress: $playerViewModel.progress,
          duration: $playerViewModel.duration,
          volume: $playerViewModel.volume,
          audioService: playerViewModel.audioService
        )

        // Visual Time Progress - Using ViewModel methods
        WinampProgressSection(
          progress: $playerViewModel.progress,
          duration: $playerViewModel.duration,
          onSeek: playerViewModel.seekTo
        )
        .onReceive(playerViewModel.audioService.$currentTime) { newTime in
          playerViewModel.progress = newTime
        }

        // Control Panel - Using ViewModel methods
        WinampControlPanelSection(
          isPlaying: $playerViewModel.isPlaying,
          togglePlay: playerViewModel.togglePlay,
          playNext: playerViewModel.playPrevious, // Note: swap due to UI layout
          playPrevious: playerViewModel.playNext,
          stop: playerViewModel.stop,
          importFolder: playerViewModel.importFolder, // TODO: Implement this
          isShuffle: $playerViewModel.isShuffle,
          isRepeat: $playerViewModel.isRepeat,
          volume: playerViewModel.volumeBinding,  // Bind to AudioService volume through ViewModel
          audioService: playerViewModel.audioService
        )

        // Equalizer (shown when toggle is on) - Using EqualizerViewModel
        if showEqualizer {
          WinampEqualizerSection(gains: $equalizerViewModel.gains)
            .onChange(of: equalizerViewModel.gains) { newGains in
              equalizerViewModel.applyCurrentSettings()
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
          songs: $playerViewModel.songs,
          currentSong: $playerViewModel.currentSong,
          showPlaylist: $showPlaylist,
          isPlaying: $playerViewModel.isPlaying,
          onReadMp3: {},
          onAudioStop: {}
        )
        .frame(width: 275, height: 580)
        .transition(.move(edge: .trailing))
      }
    }
    .onChange(of: playerViewModel.currentSong) { _ in
      playerViewModel.handleCurrentSongChange()
    }
    .onAppear {
      setupKeyboardShortcuts()
    }
  }

  func setupKeyboardShortcuts() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      switch event.keyCode {
      case 49:  // Space bar
        playerViewModel.togglePlay()
        return nil
      case 123:  // Left arrow
        playerViewModel.playPrevious()
        return nil
      case 124:  // Right arrow
        playerViewModel.playNext()
        return nil
      case 125:  // Down arrow
        playerViewModel.stop()
        return nil
      default:
        return event
      }
    }
  }
}
