//
//  ClaudeCodeManager.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

//  ClaudeCodeManager.swift: tracks Claude Code activity via per-session state
//  files in ~/.claude/notch-status/, written by Claude Code hooks
//  (UserPromptSubmit/PostToolUse -> "running", Stop -> "done", SessionEnd deletes).
//  Polls the directory every 0.5s on a serial background queue; file mtime is
//  the timestamp, so the 15s "done" decay and stale-session expiry both fall
//  out of re-reading mtimes each tick — no extra timers needed.

import Foundation
import Combine

enum ClaudeActivity { case inactive, running, done }

class ClaudeCodeManager: ObservableObject {
    @Published var activity: ClaudeActivity = .inactive

    private var pollTimer: AnyCancellable?
    private let pollQueue = DispatchQueue(label: "notchlite.claude", qos: .utility)

    private static let statusDir = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/notch-status", isDirectory: true)

    // "running" entries older than this are treated as dead sessions
    // (terminal killed before the Stop hook could fire); PostToolUse acts
    // as a heartbeat keeping live tasks fresher than this.
    private static let runningStaleInterval: TimeInterval = 10 * 60
    private static let doneDisplayInterval:  TimeInterval = 15

    init() {
        pollTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.poll() }
        poll()
    }

    private func poll() {
        pollQueue.async { [weak self] in
            guard let self else { return }
            let result = Self.scanStatusDir()
            DispatchQueue.main.async {
                if self.activity != result {
                    self.activity = result
                }
            }
        }
    }

    private static func scanStatusDir() -> ClaudeActivity {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: statusDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return .inactive }

        let now = Date()
        var anyRunning = false
        var anyRecentDone = false

        for file in files {
            guard let mtime = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
                  let state = try? String(contentsOf: file, encoding: .utf8)
            else { continue }

            let age = now.timeIntervalSince(mtime)
            switch state.trimmingCharacters(in: .whitespacesAndNewlines) {
            case "running" where age < runningStaleInterval:
                anyRunning = true
            case "done" where age < doneDisplayInterval:
                anyRecentDone = true
            default:
                try? fm.removeItem(at: file)   // expired or unrecognized — clean up
            }
        }

        if anyRunning { return .running }
        if anyRecentDone { return .done }
        return .inactive
    }
}
