//
//  AppDelegate.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NotchPanel?
    var spotifyManager: SpotifyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // removes dock icon !!!
        let spotify = SpotifyManager()
        spotifyManager = spotify
        let notchState = NotchState(spotify: spotify)
        panel = NotchPanel(state: notchState, spotify: spotify)
        panel?.orderFrontRegardless()            // show without stealing focus
    }
}
