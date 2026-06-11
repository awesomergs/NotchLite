//
//  SpotifyManager.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

//  SpotifyManager.swift: polls Spotify via NSAppleScript every second on a
//  serial background queue (scriptQueue). Creates a fresh NSAppleScript each tick
//  to avoid any thread-safety concerns with shared script state. Publishes
//  title, artist, isPlaying, isShuffling, isRepeating, playerPosition, trackDuration;
//  fetches artwork URL lazily on change. Duration comes back in ms from Spotify.


import AppKit
import Combine

class SpotifyManager: ObservableObject {
    @Published var trackTitle  = ""
    @Published var artist      = ""
    @Published var artwork: NSImage? = nil
    @Published var isPlaying      = false
    @Published var isShuffling    = false
    @Published var isRepeating    = false
    @Published var playerPosition: Double = 0   // seconds
    @Published var trackDuration:  Double = 0   // seconds

    private var pollTimer: AnyCancellable?
    private var lastArtworkURL = ""
    private let scriptQueue = DispatchQueue(label: "notchlite.spotify", qos: .utility)

    init() {
        pollTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.poll() }
        poll()
    }

    private func poll() {
        scriptQueue.async { [weak self] in
            let source = """
            tell application "Spotify"
                if it is running then
                    set t to current track
                    set artURL to ""
                    try
                        set artURL to artwork url of t
                    end try
                    return (name of t) & "|" & ¬
                           (artist of t) & "|" & ¬
                           (player state as string) & "|" & ¬
                           (shuffling as string) & "|" & ¬
                           (repeating as string) & "|" & ¬
                           artURL & "|" & ¬
                           (player position as string) & "|" & ¬
                           (duration of t as string)
                end if
                return ""
            end tell
            """
            guard let script = NSAppleScript(source: source) else { return }
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if let err = error {
                print("[Spotify] script error: \(err)")
                return
            }
            self?.handle(result.stringValue ?? "")
        }
    }

    private func handle(_ raw: String) {
        guard !raw.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.trackTitle.isEmpty else { return }
                self.trackTitle  = ""
                self.artist      = ""
                self.artwork     = nil
                self.isPlaying   = false
                self.isShuffling = false
                self.isRepeating = false
                self.lastArtworkURL = ""
            }
            return
        }
        let p = raw.components(separatedBy: "|")
        guard p.count >= 5 else { return }

        let title     = p[0]
        let artistStr = p[1]
        let playing   = p[2] == "playing"
        let shuffling = p[3] == "true"
        let repeating = p[4] == "true"
        let artURL   = p.count > 5 ? p[5] : ""
        let position = Double(p.count > 6 ? p[6] : "") ?? 0
        let durMS    = Double(p.count > 7 ? p[7] : "") ?? 0

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.trackTitle      = title
            self.artist          = artistStr
            self.isPlaying       = playing
            self.isShuffling     = shuffling
            self.isRepeating     = repeating
            self.playerPosition  = position
            self.trackDuration   = durMS / 1000.0
            if !artURL.isEmpty, artURL != self.lastArtworkURL {
                self.lastArtworkURL = artURL
                self.fetchArtwork(artURL)
            }
        }
    }

    func previousTrack()       { command("previous track") }
    func playPause()           { command("playpause") }
    func nextTrack()           { command("next track") }
    func toggleShuffle()       { command("set shuffling to not shuffling") }
    func toggleRepeat()        { command("set repeating to not repeating") }
    func seek(to seconds: Double) { command("set player position to \(seconds)") }

    private func command(_ cmd: String) {
        scriptQueue.async {
            let src = "tell application \"Spotify\" to \(cmd)"
            guard let s = NSAppleScript(source: src) else { return }
            var err: NSDictionary?
            s.executeAndReturnError(&err)
        }
    }

    private func fetchArtwork(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = NSImage(data: data) else { return }
            DispatchQueue.main.async { self?.artwork = img }
        }.resume()
    }
}
