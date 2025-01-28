// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CatMode",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "CatMode", targets: ["CatMode"])
    ],
    dependencies: [
        .package(url: "https://github.com/shpakovski/MASShortcut.git", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "CatMode",
            dependencies: ["MASShortcut"],
            path: "CatMode"
        )
    ]
)
