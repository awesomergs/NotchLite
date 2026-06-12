//
//  CapsLockManager.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import AppKit
import Combine

class CapsLockManager: ObservableObject {
    @Published var capsLockOn: Bool = false

    private var timer: AnyCancellable?

    init() {
        capsLockOn = Self.check()
        timer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                let now = Self.check()
                if self?.capsLockOn != now { self?.capsLockOn = now }
            }
    }

    private static func check() -> Bool {
        CGEventSource.flagsState(.combinedSessionState).contains(.maskAlphaShift)
    }
}
