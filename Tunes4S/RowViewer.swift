//
//  RowViewer.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 05/08/22.
//

import SwiftUI
import MediaPlayer

struct RowViewer: View {
    
    
    var item:Song
    
    @State var selectedBtn: Int = 1
    @State private var isPressed = false
    @State private var buttonImage = "play.circle.fill"
    @State private var audioPlayer: AVAudioPlayer!

    
    var body: some View {
        
        
         
        HStack {
            Button(action: {
                
                isPressed.toggle()
                if (isPressed) {
                    self.selectedBtn = item.id
                    buttonImage="stop.circle.fill"
                    print("playing")
                    
                    let url = URL(fileURLWithPath: item.file)

                    self.audioPlayer = try! AVAudioPlayer(contentsOf: url)
                    self.audioPlayer.play()
                        
                    
                } else {
                    self.selectedBtn = -1
                    print("stopped")
                    buttonImage="play.circle.fill"
                    self.audioPlayer.stop()
                }
            }) {
                Image(systemName: self.selectedBtn == item.id ? "stop.circle.fill" : "play.circle.fill")
                    .resizable(capInsets: EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
                    .aspectRatio(contentMode: .fit)
                    .padding(.leading, 0.0)
                    .frame(width: 20.0, height: 20.0)
                    
            }
//                .background(self.selectedBtn == item.id ? Color.red : Color.blue)
            .clipShape(Circle())
            //.cornerRadius(100)
            //.shadow(radius: 10)
    
            if item.songImage != nil {
                Image(nsImage: NSImage(data: item.songImage!)!)
                    .resizable()
                    .frame(width: 30.0, height: 30.0)
            } else {
                Image(systemName: "music.note")
                    .frame(width: 30.0, height: 30.0)
            }

              
            Text(item.title)
                .fixedSize()
                .frame(width: 180, alignment: .leading)
            Text(item.album)
                .fixedSize()
                .frame(width: 150, alignment: .leading)
            Text(item.file)
            
        }
        
        
        Divider()
            .padding(/*@START_MENU_TOKEN@*/.all, 2.0/*@END_MENU_TOKEN@*/)
            
            
            
        
        
    }
}

struct RowViewer_Previews: PreviewProvider {
    static var previews: some View {
        RowViewer(item: Song(id: 1, title: "Title1", album:"Album1", artist: "Artist1", file:"/Library/Test1/song.mp3"))
    }
}
