//
//  NotchState.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import SwiftUI
import Combine

enum MusicDisplayMode { case hidden, playing, paused }

class NotchState: ObservableObject {
    @Published var isExpanded = false
    @Published var musicMode: MusicDisplayMode = .hidden
    @Published var claudeMode: ClaudeActivity = .inactive

    private var collapseTask: Task<Void, Never>?
    private var pauseCollapseTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(spotify: SpotifyManager, claude: ClaudeCodeManager) {
        spotify.$isPlaying
            .combineLatest(spotify.$trackTitle)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying, title in
                self?.handlePlayback(isPlaying: isPlaying, hasTrack: !title.isEmpty)
            }
            .store(in: &cancellables)

        claude.$activity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activity in
                guard let self, self.claudeMode != activity else { return }
                withAnimation(.easeOut(duration: 0.3)) { self.claudeMode = activity }
            }
            .store(in: &cancellables)
    }

    private func handlePlayback(isPlaying: Bool, hasTrack: Bool) {
        guard hasTrack else {
            pauseCollapseTask?.cancel()
            pauseCollapseTask = nil
            if musicMode != .hidden {
                withAnimation(.easeOut(duration: 0.3)) { musicMode = .hidden }
            }
            return
        }

        if isPlaying {
            pauseCollapseTask?.cancel()
            pauseCollapseTask = nil
            withAnimation(.easeOut(duration: 0.3)) { musicMode = .playing }
        } else if musicMode == .playing {
            // only start the timer on the playing → paused transition,
            // so repeated paused polls don't reset it or re-show after timeout
            withAnimation(.easeOut(duration: 0.2)) { musicMode = .paused }
            pauseCollapseTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) { self.musicMode = .hidden }
                self.pauseCollapseTask = nil
            }
        }
    }

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
