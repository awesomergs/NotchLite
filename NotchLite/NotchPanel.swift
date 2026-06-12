//
//  NotchPanel.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import AppKit
import SwiftUI
import Combine

class NotchPanel: NSPanel {
    private var cancellables = Set<AnyCancellable>()
    private let screenFrame: NSRect

    private static let collapsedSize        = CGSize(width: 200, height: 32)
    private static let musicSize            = CGSize(width: 310, height: 32)
    private static let calendarExpandedSize = CGSize(width: 380, height: 145)
    private static let splitExpandedSize    = CGSize(width: 520, height: 145)
    private static let claudeExtraWidth: CGFloat = 44   // rightward extension for the Claude indicator
    private static let capsLockExtraLeft: CGFloat = 40  // leftward extension for the CapsLock indicator

    init(state: NotchState, spotify: SpotifyManager, calendar: CalendarManager) {
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main!
        screenFrame = screen.frame

        let startRect = NotchPanel.frame(for: NotchPanel.collapsedSize, in: screen.frame)

        super.init(
            contentRect: startRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovable = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
//        self.sharingType = .readOnly   // TEMP: allow screenshot verification

        let hosting = NSHostingView(rootView: NotchView(state: state, spotify: spotify, calendar: calendar))
        hosting.autoresizingMask = [.width, .height]   // grow with the window
        self.contentView = hosting

        state.$isExpanded
            .combineLatest(state.$musicMode, state.$claudeMode)
            .combineLatest(state.$capsLockVisible)
            .sink { [weak self] args, capsLockVisible in
                let (expanded, musicMode, claudeMode) = args
                self?.resize(expanded: expanded, musicMode: musicMode, claudeMode: claudeMode, capsLockVisible: capsLockVisible)
            }
            .store(in: &cancellables)
    }

    // x shifts left by extraLeft so the base notch stays centered; extra width
    // grows off the left edge (extraLeft) or right edge (extraRight)
    private static func frame(for size: CGSize, extraRight: CGFloat = 0, extraLeft: CGFloat = 0, in screen: NSRect) -> NSRect {
        NSRect(
            x: screen.midX - size.width / 2 - extraLeft,
            y: screen.maxY - size.height,
            width: size.width + extraRight + extraLeft,
            height: size.height
        )
    }

    private func resize(expanded: Bool, musicMode: MusicDisplayMode, claudeMode: ClaudeActivity, capsLockVisible: Bool) {
        let size: CGSize
        if expanded {
            size = musicMode == .playing ? NotchPanel.splitExpandedSize : NotchPanel.calendarExpandedSize
        } else if musicMode != .hidden {
            size = NotchPanel.musicSize
        } else {
            size = NotchPanel.collapsedSize
        }
        let extraRight = (!expanded && claudeMode != .inactive) ? NotchPanel.claudeExtraWidth : 0
        // only extend left when capslock is briefly shown AND music isn't present (music provides existing left space)
        let extraLeft: CGFloat = (!expanded && capsLockVisible && musicMode == .hidden) ? NotchPanel.capsLockExtraLeft : 0
        let target = NotchPanel.frame(for: size, extraRight: extraRight, extraLeft: extraLeft, in: screenFrame)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(target, display: true)
        }
    }
}
