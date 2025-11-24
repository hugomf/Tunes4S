import Foundation

public class Song: ObservableObject, Identifiable, Equatable {
    public var id: Int
    @Published var title: String
    @Published var album: String
    @Published var artist: String
    let file: String
    @Published var songImage: Data?
    var duration: Double

    init(id: Int, title: String, album: String, artist: String,
         file: String, songImage: Data?, duration: Double = 0) {
        self.id = id
        self.title = title
        self.album = album
        self.artist = artist
        self.file = file
        self.songImage = songImage
        self.duration = duration
    }

    public static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
