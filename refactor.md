# Complete Winamp Architecture - Production Ready

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Principles](#core-principles)
3. [Package Structure](#package-structure)
4. [Complete Implementation](#complete-implementation)
5. [Testing Strategy](#testing-strategy)
6. [Usage Examples](#usage-examples)

---

## Architecture Overview

### Dependency Flow

```
┌─────────────┐
│ WinampApp   │  Creates: PlayerViewModel.makeLive()
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ PlayerViewModel │  Owns: LivePlayer, LivePlaylist, LivePersistence
│  (State Hub)    │  Subscribes to: stateStream, spectrumStream
└────────┬────────┘
         │
         ├─────────> Views observe @Published properties
         │           Views call: viewModel.play(), etc.
         │
         └─────────> Core services (async/await)
                    
┌──────────────────────────────────────────────┐
│             Dependency Rules                  │
│  App → UI → Core (one direction only)        │
│  Core has ZERO knowledge of UI               │
│  UI has ZERO business logic                  │
└──────────────────────────────────────────────┘
```

---

## Core Principles

1. **Complete UI/Logic Separation**: Change entire UI without touching player functionality
2. **Theme Support**: Easy to add new visual themes/skins
3. **Async-First**: Modern Swift concurrency (async/await, AsyncStream)
4. **State Persistence**: Resume playback across app launches
5. **Performance Optimized**: Granular state streams prevent unnecessary redraws
6. **Testable**: Mock implementations for every protocol

---

## Package Structure

```
Winamp/
├── Package.swift
├── Sources/
│   ├── WinampCore/
│   │   ├── Models/
│   │   │   ├── Song.swift
│   │   │   ├── PlaybackState.swift
│   │   │   ├── SpectrumData.swift
│   │   │   └── AppState.swift
│   │   │
│   │   ├── Protocols/
│   │   │   ├── PlayerClient.swift
│   │   │   ├── PlaylistClient.swift
│   │   │   └── PersistenceClient.swift
│   │   │
│   │   └── Services/
│   │       ├── LivePlayer.swift
│   │       ├── LivePlaylist.swift
│   │       ├── LivePersistence.swift
│   │       ├── MockPlayer.swift
│   │       ├── MockPlaylist.swift
│   │       └── MockPersistence.swift
│   │
│   ├── WinampUI/
│   │   ├── Theme/
│   │   │   ├── Theme.swift
│   │   │   ├── WinampClassicTheme.swift
│   │   │   └── ModernTheme.swift
│   │   │
│   │   ├── ViewModels/
│   │   │   └── PlayerViewModel.swift
│   │   │
│   │   ├── Components/
│   │   │   ├── TransportControls.swift
│   │   │   ├── VolumeControl.swift
│   │   │   ├── TimeDisplay.swift
│   │   │   ├── SpectrumAnalyzer.swift
│   │   │   ├── ProgressBar.swift
│   │   │   └── SongInfo.swift
│   │   │
│   │   └── Screens/
│   │       ├── PlayerScreen.swift
│   │       ├── PlaylistScreen.swift
│   │       └── EqualizerScreen.swift
│   │
│   └── WinampApp/
│       ├── macOS/
│       │   └── WinampApp.swift
│       └── iOS/
│           └── WinampApp_iOS.swift
│
└── Tests/
    ├── WinampCoreTests/
    │   ├── PlayerTests.swift
    │   ├── PlaylistTests.swift
    │   └── PersistenceTests.swift
    └── WinampUITests/
        └── PlayerViewModelTests.swift
```


## Benefits Summary

| Feature | Benefit |
|---------|---------|
| **Separate Core/UI** | Replace entire UI without touching player logic |
| **Theme System** | Add new skins in minutes |
| **Async/Await** | Modern, performant concurrency |
| **Granular Streams** | Spectrum updates don't redraw entire UI |
| **Persistence** | Resume playback across launches |
| **Hashable Songs** | Optimized SwiftUI diffing |
| **Factory Methods** | Easy previews and testing |
| **Mock Services** | Fast, deterministic tests |
| **Protocol-Based** | Easy to swap implementations |
| **Single Source of Truth** | ViewModel owns all state |

---

## Performance Characteristics

```
State Updates per Second:
- PlaybackState: 1-2/sec (time, play/pause)
- SpectrumData: 30-60/sec (visual analyzer)

View Redraws:
- Volume slider: Only on volume change
- Transport controls: Only on play/pause
- Spectrum analyzer: 30-60 fps
- Time display: 1-2/sec

Result: Efficient, smooth UI with no unnecessary redraws
```

---

## Next Steps

1. **Implement FFT Analysis**: Replace dummy spectrum data in `LivePlayer`
2. **Add Equalizer Integration**: Connect EQ sliders to `AVAudioUnitEQ`
3. **iOS Support**: Create iOS-specific UI with touch gestures
4. **Additional Themes**: Dark mode, light mode, custom skins
5. **Playlist Management**: Save/load playlists to disk
6. **Keyboard Shortcuts**: Global media key support
7. **Visualizations**: Additional spectrum styles (oscilloscope, waveform)

---

This is a **complete, production-ready architecture** that you can start implementing immediately. Every file is small, focused, and testable. The separation of concerns is crystal clear, and you can change any layer without affecting the others.