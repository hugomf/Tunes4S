//
//  ImportFolderView.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI
import ID3TagEditor

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
        
        let id3TagEditor = ID3TagEditor()
        
        do {
            if let id3Tag = try id3TagEditor.read(from: path) {
                let tagContentReader = ID3TagContentReader(id3Tag: id3Tag)
                
                
                let title = tagContentReader.title() ?? ""
                let album = tagContentReader.album() ?? ""
                let songImage = tagContentReader.attachedPictures()[0] as? ID3FrameAttachedPicture
            
                print(title)
                //print(tagContentReader.artist() ?? "")
                
                return Song(
                    id: id,
                    title: title,
                    album: album,
                    file: path,
                    songImage: songImage)
            }
        } catch  {
            print(error)
        }
        return nil
        
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
