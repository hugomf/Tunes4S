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
        
    struct MainContentView: View {
        @State private var songs:[Song] = []
        @State private var searchText = ""
        
        var filteredSongs: [Song] {
            if searchText.isEmpty {
                return songs
            }
            return songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.album.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Header with gradient
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "1DB954"), Color(hex: "121212")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Library")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(songs.count) songs")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 32)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                
                // Content area
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14))
                        
                        TextField("Search songs or albums", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Import button
                    ImprovedImportFolderView(songs: $songs)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                    
                    // Song list
                    ImprovedSongListView(songs: $songs, filteredSongs: filteredSongs)
                    
                    Spacer()
                }
                .background(Color(hex: "121212"))
            }
            .background(Color(hex: "121212"))
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            NavigationView {
                ImprovedLeftNavigationView()
                    .frame(minWidth: 200)
                MainContentView()
            }
        }
    }
}

// Improved Left Navigation
struct ImprovedLeftNavigationView: View {
    let options: [Option] = [
        .init(title: "Home", imageName: "house.fill"),
        .init(title: "Search", imageName: "magnifyingglass"),
        .init(title: "Library", imageName: "books.vertical.fill"),
        .init(title: "My Playlists", imageName: "music.note.list"),
        .init(title: "Settings", imageName: "gear"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "1DB954"))
                Text("Tunes4S")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            
            // Navigation options
            ForEach(options, id: \.self) { option in
                HStack(spacing: 16) {
                    Image(systemName: option.imageName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24)
                    
                    Text(option.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.leading, 24)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

// Improved Import Folder View
struct ImprovedImportFolderView: View {
    @Binding var songs:[Song]
    
    var body: some View {
        HStack {
            Button(action: importFolder) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Import Folder")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "1DB954"))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        print("Found \(item)")
                        let song = readMp3(path: path + "/" + item, id: songs.count)
                        if song != nil {
                            songs.append(song!)
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
                
                print(title)
                
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
}

// Improved Song List View
struct ImprovedSongListView: View {
    @Binding var songs:[Song]
    var filteredSongs: [Song]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Table header
                HStack(spacing: 16) {
                    Text("#")
                        .frame(width: 40)
                    Text("")
                        .frame(width: 50)
                    Text("TITLE")
                        .frame(width: 220, alignment: .leading)
                    Text("ALBUM")
                        .frame(width: 200, alignment: .leading)
                    Spacer()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 32)
                
                // Song rows
                ForEach(Array(filteredSongs.enumerated()), id: \.element) { index, song in
                    ImprovedRowViewer(item: song, index: index + 1)
                }
            }
        }
    }
}

// Improved Row Viewer
struct ImprovedRowViewer: View {
    var item: Song
    var index: Int
    
    @State var selectedBtn: Int = -1
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var audioPlayer: AVAudioPlayer!
    
    var body: some View {
        HStack(spacing: 16) {
            // Index / Play button
            ZStack {
                if isHovered && !isPressed {
                    Button(action: togglePlay) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if isPressed {
                    Button(action: togglePlay) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "1DB954"))
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text("\(index)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: 40)
            
            // Album artwork
            if item.songImage != nil {
                Image(nsImage: NSImage(data: item.songImage!.picture)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 16))
                }
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            }
            
            // Title
            Text(item.title)
                .font(.system(size: 14))
                .foregroundColor(isPressed ? Color(hex: "1DB954") : .white)
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)
            
            // Album
            Text(item.album)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)
            
            Spacer()
            
            // File path (truncated)
            Text(item.file.split(separator: "/").last.map(String.init) ?? "")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
        .background(isHovered ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    func togglePlay() {
        isPressed.toggle()
        
        if isPressed {
            selectedBtn = item.id
            print("playing")
            
            let url = URL(fileURLWithPath: item.file)
            audioPlayer = try! AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        } else {
            selectedBtn = -1
            print("stopped")
            audioPlayer.stop()
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
