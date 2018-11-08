// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "AndroidBluetooth",
    products: [
        .library(
            name: "AndroidBluetooth",
            targets: ["AndroidBluetooth"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Android.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "AndroidBluetooth",
            dependencies: [
                "Android",
                "Bluetooth",
                "GATT"
            ]),
        .testTarget(
            name: "AndroidBluetoothTests",
            dependencies: ["AndroidBluetooth"]
        )
    ]
)
