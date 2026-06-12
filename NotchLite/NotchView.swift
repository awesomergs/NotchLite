//
//  NotchView.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

import SwiftUI
import Combine

struct NotchView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var spotify: SpotifyManager
    @ObservedObject var calendar: CalendarManager

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(bottomLeadingRadius: 18, bottomTrailingRadius: 18)
                .fill(.black)

            if state.isExpanded {
                if state.musicMode == .playing {
                    SplitExpandedView(spotify: spotify, calendar: calendar)
                        .padding(.top, 36)
                        .transition(.opacity)
                } else {
                    CalendarOnlyExpandedView(calendar: calendar)
                        .padding(.top, 36)
                        .transition(.opacity)
                }
            } else if state.musicMode != .hidden {
                HStack(spacing: 0) {
                    AlbumArtThumbnail(image: spotify.artwork)
                        .padding(.leading, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                    Spacer()
                    if state.claudeMode != .inactive {
                        ClaudeIndicatorView(activity: state.claudeMode)
                            .padding(.trailing, 12)
                            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
                    } else {
                        AudioBarsView(isPlaying: state.musicMode == .playing)
                            .padding(.trailing, 8)
                            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.opacity)
            } else if state.claudeMode != .inactive {
                HStack(spacing: 0) {
                    Spacer()
                    ClaudeIndicatorView(activity: state.claudeMode)
                        .padding(.trailing, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
                }
                .frame(maxHeight: .infinity)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onHover { hovering in
            state.setHovering(hovering)
        }
    }
}

// MARK: - Expanded layouts

struct SplitExpandedView: View {
    @ObservedObject var spotify: SpotifyManager
    @ObservedObject var calendar: CalendarManager

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CompactSpotifySection(spotify: spotify)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 6)

            CalendarSection(calendar: calendar)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct CalendarOnlyExpandedView: View {
    @ObservedObject var calendar: CalendarManager

    var body: some View {
        CalendarSection(calendar: calendar)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 14)
    }
}

// MARK: - Compact Spotify (split mode)

struct CompactSpotifySection: View {
    @ObservedObject var spotify: SpotifyManager

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 8) {
                AlbumArtThumbnail(image: spotify.artwork, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spotify.trackTitle.isEmpty ? "Not Playing" : spotify.trackTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(spotify.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
            }

            TrackProgressBar(
                position: spotify.playerPosition,
                duration: spotify.trackDuration,
                onSeek: { spotify.seek(to: $0) }
            )

            HStack(spacing: 0) {
                Spacer()
                compactButton(icon: "backward.end.fill") { spotify.previousTrack() }
                Spacer()
                compactButton(icon: spotify.isPlaying ? "pause.fill" : "play.fill", size: 18) { spotify.playPause() }
                Spacer()
                compactButton(icon: "forward.end.fill") { spotify.nextTrack() }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func compactButton(icon: String, size: CGFloat = 13, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar section

struct CalendarSection: View {
    @ObservedObject var calendar: CalendarManager

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            calendarContent(now: context.date)
        }
    }

    @ViewBuilder
    private func calendarContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if calendar.events.isEmpty {
                Text("No events today")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text(calendar.showingTomorrow ? "Tomorrow" : "Today")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 5)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(calendar.events.prefix(5)) { event in
                        EventRow(event: event, now: now)
                    }
                }
            }
        }
    }
}

struct EventRow: View {
    let event: CalendarEvent
    let now: Date

    private var isActive: Bool {
        !event.isAllDay && event.startDate <= now && now < event.endDate
    }

    private var isImminent: Bool {
        !event.isAllDay && now < event.startDate && event.startDate.timeIntervalSince(now) <= 300
    }

    private var isHighlighted: Bool { isActive || isImminent }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isHighlighted ? Color.green : event.calendarColor)
                .frame(width: 5, height: 5)
            Text(event.isAllDay ? "All day" : isActive ? "now" : Self.timeFormatter.string(from: event.startDate))
                .font(.system(size: 9, weight: isActive ? .bold : .medium).monospacedDigit())
                .foregroundStyle(isActive ? Color.green : .white.opacity(0.45))
                .fixedSize()
            Text(event.title)
                .font(.system(size: 10, weight: isHighlighted ? .semibold : .medium))
                .foregroundStyle(isHighlighted ? .white : .white.opacity(0.85))
                .lineLimit(1)
            if let url = event.meetingURL {
                Spacer()
                JoinButton(url: url, isActive: isActive)
            }
        }
        .padding(.horizontal, isHighlighted ? 6 : 0)
        .padding(.vertical, isHighlighted ? 3 : 0)
        .background {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.15))
            }
        }
    }
}

struct JoinButton: View {
    let url: URL
    let isActive: Bool

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "video.fill")
                    .font(.system(size: 7))
                Text("Join")
                    .font(.system(size: 9, weight: .semibold))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(isActive ? Color.black : .white.opacity(0.85))
            .background {
                if isActive {
                    Capsule().fill(Color.green)
                } else {
                    Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared subviews

struct AlbumArtThumbnail: View {
    let image: NSImage?
    var size: CGFloat = 20

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundStyle(.white.opacity(0.4))
                            .font(.system(size: size * 0.45))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.14))
    }
}

struct AudioBarsView: View {
    let isPlaying: Bool

    private let freqs:  [Double] = [4.1, 5.8, 3.6, 6.4]
    private let phases: [Double] = [0.0, 1.1, 2.3, 0.7]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isPlaying)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 1.5) {
                ForEach(0..<4, id: \.self) { i in
                    let h: CGFloat = isPlaying
                        ? 3 + 12 * CGFloat((sin(t * freqs[i] + phases[i]) + 1) / 2)
                        : 4
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.18, green: 0.84, blue: 0.38))
                        .frame(width: 2.5, height: h)
                        .animation(.easeOut(duration: 0.35), value: isPlaying)
                }
            }
        }
        .frame(width: 16, height: 20)
    }
}

struct TrackProgressBar: View {
    let position: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragFraction: Double = 0

    private var progress: Double {
        isDragging ? dragFraction : (duration > 0 ? min(position / duration, 1) : 0)
    }

    private func format(_ t: Double) -> String {
        let s = Int(max(0, t))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)
                    Capsule()
                        .fill(.white.opacity(isDragging ? 1.0 : 0.75))
                        .frame(width: max(0, geo.size.width * progress), height: 3)
                        .animation(isDragging ? nil : .linear(duration: 1.0), value: progress)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            isDragging = true
                            dragFraction = max(0, min(1, v.location.x / geo.size.width))
                        }
                        .onEnded { v in
                            let f = max(0, min(1, v.location.x / geo.size.width))
                            onSeek(f * duration)
                            isDragging = false
                        }
                )
            }
            .frame(height: 8)

            HStack {
                Text(format(isDragging ? dragFraction * duration : position))
                Spacer()
                Text(format(duration))
            }
            .font(.system(size: 9, weight: .medium).monospacedDigit())
            .foregroundStyle(.white.opacity(isDragging ? 0.6 : 0.35))
        }
    }
}

struct PlayerControlsView: View {
    @ObservedObject var spotify: SpotifyManager

    var body: some View {
        HStack {
            Spacer()
            controlButton(icon: "shuffle", active: spotify.isShuffling) { spotify.toggleShuffle() }
            Spacer()
            controlButton(icon: "backward.end.fill") { spotify.previousTrack() }
            Spacer()
            controlButton(icon: spotify.isPlaying ? "pause.fill" : "play.fill", size: 20) { spotify.playPause() }
            Spacer()
            controlButton(icon: "forward.end.fill") { spotify.nextTrack() }
            Spacer()
            controlButton(icon: "repeat", active: spotify.isRepeating) { spotify.toggleRepeat() }
            Spacer()
        }
    }

    @ViewBuilder
    private func controlButton(icon: String, active: Bool = true, size: CGFloat = 15, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(active ? .white : .white.opacity(0.35))
                .frame(width: 32, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
