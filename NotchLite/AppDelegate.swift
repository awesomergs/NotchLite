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
    let state = NotchState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // removes dock icon !!!
        panel = NotchPanel(state: state)
        panel?.orderFrontRegardless()            // show without stealing focus
    }
}
