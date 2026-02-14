// swift-tools-version:6.2
import PackageDescription
import CompilerPluginSupport

import class Foundation.FileManager
import class Foundation.ProcessInfo

// Get NDK version from command line
let environment = ProcessInfo.processInfo.environment
let ndkVersion = environment["ANDROID_NDK_VERSION"].flatMap { UInt($0) } ?? 27
let ndkVersionDefine = SwiftSetting.define("ANDROID_NDK_VERSION_" + ndkVersion.description)

// Get Android API version
let sdkVersion = environment["ANDROID_SDK_VERSION"].flatMap { UInt($0) } ?? 29
let sdkVersionDefine = SwiftSetting.define("ANDROID_SDK_VERSION_" + ndkVersion.description)

let package = Package(
    name: "AndroidBluetooth",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AndroidBluetooth",
            targets: ["AndroidBluetooth"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Android.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "7.2.0"
        )
    ],
    targets: [
        .target(
            name: "AndroidBluetooth",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                ),
                .product(
                    name: "AndroidKit",
                    package: "Android"
                )
            ],
            exclude: ["swift-java.config"],
            swiftSettings: [
              .swiftLanguageMode(.v5),
              ndkVersionDefine,
              sdkVersionDefine
            ],
            plugins: [
                //.plugin(name: "SwiftJavaPlugin", package: "swift-java")
            ]
        )
    ]
)
