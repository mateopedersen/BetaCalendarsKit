// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BetaCalendarsKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "BetaCalendarsCore", targets: ["BetaCalendarsCore"]),
        .library(name: "BetaCalendarsRecurrence", targets: ["BetaCalendarsRecurrence"]),
        .library(name: "BetaCalendarsFixtures", targets: ["BetaCalendarsFixtures"]),
        .executable(name: "betacal", targets: ["betacal"]),
    ],
    targets: [
        .target(name: "BetaCalendarsCore"),
        .target(name: "BetaCalendarsRecurrence", dependencies: ["BetaCalendarsCore"]),
        .target(name: "BetaCalendarsFixtures", dependencies: ["BetaCalendarsCore", "BetaCalendarsRecurrence"]),
        .executableTarget(
            name: "betacal", dependencies: ["BetaCalendarsCore", "BetaCalendarsRecurrence", "BetaCalendarsFixtures"]),
        .testTarget(name: "BetaCalendarsCoreTests", dependencies: ["BetaCalendarsCore"]),
        .testTarget(
            name: "BetaCalendarsRecurrenceTests", dependencies: ["BetaCalendarsCore", "BetaCalendarsRecurrence"]),
        .testTarget(name: "BetaCalendarsFixturesTests", dependencies: ["BetaCalendarsCore", "BetaCalendarsFixtures"]),
        .testTarget(
            name: "BetaCalendarsIntegrationTests",
            dependencies: ["BetaCalendarsCore", "BetaCalendarsRecurrence", "BetaCalendarsFixtures"]),
    ]
)
