//
//  NotchLiteApp.swift
//  NotchLite
//
//  Created by Rohan George on 6/11/26.
//

import SwiftUI

@main
struct NotchLiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }   // satisfies the "needs a Scene" rule, opens no window
    }
}
