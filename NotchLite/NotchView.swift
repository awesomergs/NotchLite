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

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(bottomLeadingRadius: 18, bottomTrailingRadius: 18)
                .fill(.black)

            if state.isExpanded {
                Text("expanded content goes here")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.top, 56)
                    .transition(.opacity)
            } else if state.musicMode != .hidden {
                HStack(spacing: 0) {
                    AlbumArtThumbnail(image: spotify.artwork)
                        .padding(.leading, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                    Spacer()
                    AudioBarsView(isPlaying: state.musicMode == .playing)
                        .padding(.trailing, 8)
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

struct AlbumArtThumbnail: View {
    let image: NSImage?

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
                            .font(.system(size: 11))
                    )
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 3))
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
