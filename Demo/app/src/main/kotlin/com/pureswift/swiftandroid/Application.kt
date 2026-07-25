package com.pureswift.swiftandroid

class Application : android.app.Application() {

    init {
        NativeLibrary.shared()
    }
}
