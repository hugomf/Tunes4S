import Foundation
import SwiftUI
import ID3TagEditor

//
//  Helper.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 11/07/22.
//

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public class Song: Identifiable, ObservableObject, Equatable {
    public var id: Int
    public var title: String
    public var album: String
    public var artist: String
    public var file: String
    public var songImage: Data?
    public var duration: Double = 0.0

    public init(id: Int, title: String, album: String, artist: String, file: String, songImage: Data? = nil) {
        self.id = id
        self.title = title
        self.album = album
        self.artist = artist
        self.file = file
        self.songImage = songImage
    }

    public static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
