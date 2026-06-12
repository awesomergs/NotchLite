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
    var calendarManager: CalendarManager?
    var claudeManager: ClaudeCodeManager?
    var capsLockManager: CapsLockManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // removes dock icon !!!
        let spotify = SpotifyManager()
        spotifyManager = spotify
        let calendar = CalendarManager()
        calendarManager = calendar
        let claude = ClaudeCodeManager()
        claudeManager = claude
        let capsLock = CapsLockManager()
        capsLockManager = capsLock
        let notchState = NotchState(spotify: spotify, claude: claude, capsLock: capsLock)
        panel = NotchPanel(state: notchState, spotify: spotify, calendar: calendar)
        panel?.orderFrontRegardless()            // show without stealing focus
    }
}
