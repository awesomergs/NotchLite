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

    private static let collapsedSize = CGSize(width: 200, height: 36)
    private static let expandedSize  = CGSize(width: 380, height: 180)

    init(state: NotchState) {
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

        let hosting = NSHostingView(rootView: NotchView(state: state))
        hosting.autoresizingMask = [.width, .height]   // grow with the window
        self.contentView = hosting

        // When the view flips isExpanded, resize the window to match.
        state.$isExpanded
            .removeDuplicates()
            .sink { [weak self] expanded in
                self?.resize(expanded: expanded)
            }
            .store(in: &cancellables)
    }

    // Anchor any size to the top-center of the screen.
    private static func frame(for size: CGSize, in screen: NSRect) -> NSRect {
        NSRect(
            x: screen.midX - size.width / 2,
            y: screen.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func resize(expanded: Bool) {
        let size = expanded ? NotchPanel.expandedSize : NotchPanel.collapsedSize
        let target = NotchPanel.frame(for: size, in: screenFrame)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(target, display: true)
        }
    }
}
