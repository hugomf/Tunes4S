//
//  Helper.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 01/08/22.
//

import SwiftUI
import ID3TagEditor


struct Song: Hashable {
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: Int
    var title: String
    var album: String
    var file: String
    var songImage: AttachedPicture?
    //var score: Int
}

struct Option: Hashable {
    let title: String
    let imageName: String
}
