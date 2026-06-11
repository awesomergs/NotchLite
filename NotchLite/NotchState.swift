//
//  NotchState.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import SwiftUI
import Combine

class NotchState: ObservableObject {
    @Published var isExpanded = false
    private var collapseTask: Task<Void, Never>?

    func setHovering(_ hovering: Bool) {
        if hovering {
            collapseTask?.cancel()
            collapseTask = nil
            withAnimation(.easeOut(duration: 0.2)) { isExpanded = true }
        } else {
            collapseTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000) // hysteresis - must be somewhere between 200ms and 300ms
                                                                //currently running w 250 but faced v minor issues, can also try slight reductions for smoothness
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) { self.isExpanded = false }
            }
        }
    }
}
