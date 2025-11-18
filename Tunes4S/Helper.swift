//
//  Helper.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 11/07/22.
//

import Foundation
import SwiftUI
import ID3TagEditor

struct Song: Identifiable {
    var id: Int
    var title: String
    var album: String
    var file: String
    var songImage: AttachedPicture?
}

extension Song: Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.album == rhs.album && lhs.file == rhs.file
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(album)
        hasher.combine(file)
    }
}


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
