// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Forma",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Forma", targets: ["Forma"])
    ],
    targets: [
        .target(name: "Forma"),
        .testTarget(name: "FormaTests", dependencies: ["Forma"])
    ]
)
