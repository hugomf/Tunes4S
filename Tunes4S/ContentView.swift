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
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showPlaylist = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView(showPlaylist: $showPlaylist)
                DisplayView(currentSong: $currentSong)
                ControlsView(isPlaying: $isPlaying, togglePlay: togglePlay)
                EqualizerView()
                FooterView(importFolder: importFolder)
            }
            .frame(width: 350, height: 500)
            .background(Color(hex: "2c2c2c"))
            .cornerRadius(10)
            .shadow(radius: 10)

            if showPlaylist {
                PlaylistView(songs: $songs, currentSong: $currentSong)
                    .frame(width: 350, height: 500)
                    .background(Color(hex: "2c2c2c"))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom))
            }
        }
    }

    func importFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK {
            let fm = FileManager.default
            let path = panel.url?.path ?? ""

            do {
                let items = try fm.contentsOfDirectory(atPath: path)

                for item in items {
                    if item.hasSuffix("mp3") {
                        if let song = readMp3(path: path + "/" + item, id: songs.count) {
                            songs.append(song)
                        }
                    }
                }
            } catch {
                print("Error reading directory")
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
                let songImage = tagContentReader.attachedPictures().first

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
            let url = URL(fileURLWithPath: song.file)
            audioPlayer = try! AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } else {
            audioPlayer?.stop()
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

    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "backward.fill")
            }
            Button(action: togglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: {}) {
                Image(systemName: "forward.fill")
            }
        }
        .foregroundColor(Color(hex: "ffcc00"))
        .font(.system(size: 24))
        .padding()
    }
}

struct EqualizerView: View {
    var body: some View {
        ZStack {
            Color(hex: "1c1c1c")
            Text("Equalizer (placeholder)")
                .foregroundColor(Color(hex: "ffcc00"))
        }
        .frame(height: 100)
    }
}

struct PlaylistView: View {
    @Binding var songs: [Song]
    @Binding var currentSong: Song?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            HStack {
                Text("Playlist")
                    .font(.custom("Helvetica Neue", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "ffcc00"))
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
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
