//
//  Tunes4SApp.swift
//  Tunes4S
//
//  Created by Hugo Martinez Fernandez on 31/07/22.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop audio playback when app terminates
        NotificationCenter.default.post(name: NSNotification.Name("AppWillTerminate"), object: nil)
    }
}

@main
struct Tunes4SApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
