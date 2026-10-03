// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SessionCore",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "SessionCore", targets: ["SessionCore"])],
    targets: [
        .target(name: "SessionCore", path: "QuickSleep/Core"),
        .testTarget(name: "SessionCoreTests", dependencies: ["SessionCore"], path: "Tests/SessionCoreTests")
    ]
)
