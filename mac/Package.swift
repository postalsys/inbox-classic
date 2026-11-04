// swift-tools-version: 6.2
// The Mac version of Inbox Classic: AppKit windows on the Rust core, which is linked as the static library pe-ffi
// builds (build/cargo/release/libpe_ffi.a, made by scripts/mac-build.sh before this package). The windows are a
// library, so the app and its UI end-to-end test (which runs the app in its own process and drives its windows) are
// built from the same code.
import PackageDescription

let core = Context.packageDirectory + "/../build/cargo/release"
// Sparkle (updates), the framework of its release, which scripts/mac-build.sh puts there
let sparkle = Context.packageDirectory + "/../build/sparkle"

let package = Package(
    name: "InboxClassic",
    platforms: [.macOS(.v26)],
    targets: [
        // the C header of the core (core/include/inbox_classic.h) as a Swift module
        .systemLibrary(name: "CInboxClassic", path: "Core"),
        .target(
            name: "InboxClassicKit",
            dependencies: ["CInboxClassic"],
            path: "Sources/InboxClassic",
            swiftSettings: [.swiftLanguageMode(.v5), .unsafeFlags(["-F", sparkle])],
            linkerSettings: [
                .unsafeFlags(["-L" + core, "-F", sparkle, "-framework", "Sparkle"]),
                .linkedLibrary("pe_ffi"),
                // what the Rust standard library and the core need (cargo rustc -p pe-ffi -- --print native-static-libs)
                .linkedFramework("Security"),
                .linkedFramework("CoreFoundation"),
                .linkedLibrary("iconv"),
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        ),
        .executableTarget(
            name: "InboxClassic",
            dependencies: ["InboxClassicKit"],
            path: "Sources/App",
            swiftSettings: [.swiftLanguageMode(.v5), .unsafeFlags(["-F", sparkle])],
            // Sparkle.framework is in the bundle's Frameworks
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .executableTarget(
            name: "InboxClassicUITest",
            dependencies: ["InboxClassicKit"],
            path: "Sources/UITest",
            swiftSettings: [.swiftLanguageMode(.v5), .unsafeFlags(["-F", sparkle])],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
    ]
)
