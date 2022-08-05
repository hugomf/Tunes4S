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
        
        var body: some View {
            
            VStack {
                ImportFolderView(songs: $songs)
                SongListView(songs: $songs)
                Spacer()
            }
        }
    }
    

    var body: some View {
        
        HStack {
            NavigationView {
                LeftNavigationView();
                MainContentView();
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}

