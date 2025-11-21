//
//  ImportFolderView.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI

struct ImportFolderView: View {
    
    
    @Binding var songs:[Song]
    
    @State var filename = "Filename"
    @State var showFileChooser = false

  var body: some View {
    HStack {
      Button("Import Folder")
      {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            self.filename = panel.url?.lastPathComponent ?? "<none>"
            print(panel.url?.path ?? "")
            
            let fm = FileManager.default
            let path = panel.url?.path ?? ""

            do {
                let items = try fm.contentsOfDirectory(atPath: path)

                for item in items {
                    
                    if (item.hasSuffix("mp3")) {
                        print("Found \(item)")
                        let song = readMp3(path: path + "/" + item, id: songs.count)
                        if song != nil {
                            songs.append(song!)
                        }
                    }
                }
            } catch {
                // failed to read directory – bad permissions, perhaps?
            }
            
        }
      }
    }
      
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
    
    func readMp3(path: String, id: Int) -> Song? {
        let song = Song(id: id, title: fileNameFromPath(path), album: "Unknown Album", artist: "Unknown Artist", file: path, songImage: nil)
        song.duration = 180.0 // Placeholder duration
        return song
    }

    func fileNameFromPath(_ path: String) -> String {
        return (path as NSString).lastPathComponent.replacingOccurrences(of: ".mp3", with: "")
    }
    
    
}


#if DEBUG

struct ImportFolderView_Previews: PreviewProvider {
    
    @State private static var songs:[Song] = []
    
    static var previews: some View {
        ImportFolderView(songs: $songs)
    }
}

#endif
