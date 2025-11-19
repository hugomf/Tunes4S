// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Tunes4S",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "Tunes4S", targets: ["Tunes4S"])
    ],
    dependencies: [
        .package(url: "https://github.com/chicio/ID3TagEditor.git", from: "3.2.1")
    ],
    targets: [
        .target(
            name: "Tunes4S",
            dependencies: ["ID3TagEditor"])
    ]
)
