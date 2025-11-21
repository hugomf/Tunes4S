//
//  SongListView.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI
import AVFoundation


// WinampPlaylist

struct WinampPlaylist: View {

    @Binding var songs:[Song]
    @Binding var currentSong: Song?

    @Binding var showPlaylist: Bool
    @Binding var isPlaying: Bool

    var onReadMp3: () -> Void
    var onAudioStop: () -> Void

    var body: some View {

        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(songs) { item in
                        ResponsiveRowViewer(item: item, containerWidth: geometry.size.width)
                        Divider()
                            .padding(.all, 2.0)
                    }
                }
                .padding(.vertical, 8)
                .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width)
            }
            .background(Color(hex: "2A2A2A"))
        }
    }

}

// Responsive Row Viewer that adapts to container width
struct ResponsiveRowViewer: View {

    var item: Song
    var containerWidth: CGFloat

    @State var selectedBtn: Int = 1
    @State private var isPressed = false
    @State private var buttonImage = "play.circle.fill"
    @State private var audioPlayer: AVAudioPlayer!

    var body: some View {

        HStack(spacing: 8) {
            Button(action: {
                isPressed.toggle()
                if (isPressed) {
                    self.selectedBtn = item.id
                    buttonImage = "stop.circle.fill"
                    print("playing")

                    let url = URL(fileURLWithPath: item.file)
                    self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
                    self.audioPlayer.play()

                } else {
                    self.selectedBtn = -1
                    print("stopped")
                    buttonImage = "play.circle.fill"
                    self.audioPlayer.stop()
                }
            }) {
                Image(systemName: self.selectedBtn == item.id ? "stop.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20.0, height: 20.0)
            }
            .clipShape(Circle())

            if item.songImage != nil {
                Image(nsImage: NSImage(data: item.songImage!)!)
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 30.0, height: 30.0)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text(item.artist.isEmpty ? "Unknown Artist" : item.artist)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .lineLimit(1)

                    if containerWidth > 400 {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "666666"))

                        Text(item.album.isEmpty ? "Unknown Album" : item.album)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "AAAAAA"))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            if containerWidth > 600 {
                Text(URL(fileURLWithPath: item.file).lastPathComponent)
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(1)
                    .frame(width: min(containerWidth * 0.3, 200), alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(self.selectedBtn == item.id ?
                    Color(hex: "444444").opacity(0.5) :
                    Color.clear)
    }
}

#if DEBUG
struct WinampPlaylist_Previews: PreviewProvider {

    @State static var songs:[Song] = [
        Song(id: 1, title: "title1", album: "album1", artist: "artist1", file: "/Home/hugomf/Music/Song1.mp3"),
        Song(id: 2, title: "title2", album: "album1", artist: "artist2", file: "/Home/hugomf/Music/Song2.mp3"),
        Song(id: 3, title: "title3", album: "album1", artist: "artist3", file: "/Home/hugomf/Music/Song3.mp3")
    ]

    static var previews: some View {
        WinampPlaylist(songs: $songs, currentSong: .constant(nil), showPlaylist: .constant(false), isPlaying: .constant(false), onReadMp3: {}, onAudioStop: {})
    }
}
#endif
