// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "JEVEmoji",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "JEVEmoji", targets: ["JEVEmoji"])
    ],
    targets: [
        // Pure logic with no UI: text extraction, TypeSafe API, ranking, Keychain.
        .target(name: "JEVEmojiCore"),
        // Menu bar app: hot key, panel, Accessibility reading and insertion.
        .executableTarget(
            name: "JEVEmoji",
            dependencies: ["JEVEmojiCore"],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(name: "JEVEmojiCoreTests", dependencies: ["JEVEmojiCore"])
    ]
)
