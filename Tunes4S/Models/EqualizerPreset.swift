import Foundation

enum EqualizerPreset: String, CaseIterable {
    case normal = "Normal"
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case electronic = "Electronic"

    var gains: [Float] {
        switch self {
        case .normal:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .rock:
            return [5, 4, 3, 1, -1, 1, 3, 4, 5, 5]
        case .pop:
            return [-1, 2, 4, 4, 2, -1, -1, 0, 1, 1]
        case .jazz:
            return [4, 3, 1, 2, -2, -1, 1, 2, 3, 4]
        case .classical:
            return [5, 4, 3, 2, -2, -2, 0, 2, 3, 4]
        case .electronic:
            return [5, 4, 3, 0, -1, 1, 0, 1, 3, 5]
        }
    }
}
