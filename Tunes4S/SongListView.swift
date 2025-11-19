//
//  SongListView.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI


struct SongListView: View {
    
    
   @Binding var songs:[Song]
    

    
//        @State private var sortOrder = [KeyPathComparator(\Song.title)]
        

//        let songsn = [Song(title: "title1", file: "hola", score: 20)]
    
    var body: some View {
        
        List(songs) { item in
            RowViewer(item: item)
        }

        
//            Table(selection: $selection, sortOrder: $sortOrder) {
//                TableColumn("Name", value: \.file)
//                TableColumn("Score", value: \.score) { user in
//                    Text(String(user.score))
//                }
//                .width(min: 50, max: 100)
//            } rows: {
//                ForEach(songs, content: TableRow.init)
//            }
//            .onChange(of: sortOrder) { newOrder in
//                songs.sort(using: newOrder)
//            }
        
    }
    
}

#if DEBUG
struct SongListView_Previews: PreviewProvider {
    
    @State static var songs:[Song] = [
        Song(id: 1, title: "title1", album: "album1",file: "/Home/hugomf/Music/Song1.mp3"),
        Song(id: 2, title: "title2", album: "album1", file: "/Home/hugomf/Music/Song2.mp3"),
        Song(id: 3, title: "title3", album: "album1", file: "/Home/hugomf/Music/Song3.mp3")
    ]
    
    static var previews: some View {
        SongListView(songs: $songs)
    }
}
#endif
