// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FinderTweaks",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "FinderTweaks", targets: ["FinderTweaks"]),
        .executable(name: "FinderTweaksAgent", targets: ["FinderTweaksAgent"]),
    ],
    targets: [
        .target(
            name: "FinderTweaksCore",
            swiftSettings: [
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
            ]
        ),
        .executableTarget(
            name: "FinderTweaks",
            dependencies: ["FinderTweaksCore"],
            swiftSettings: [
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-dead_strip"], .when(configuration: .release)),
            ]
        ),
        .executableTarget(
            name: "FinderTweaksAgent",
            dependencies: ["FinderTweaksCore"],
            swiftSettings: [
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-dead_strip"], .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "FinderTweaksCoreTests",
            dependencies: ["FinderTweaksCore"]
        ),
    ]
)
