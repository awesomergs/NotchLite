//
//  ClaudeLogoView.swift
//  NotchLite
//
//  Created by Rohan George on 6/12/26.
//

//  ClaudeLogoView.swift: programmatic approximation of the Claude starburst
//  logo (irregular tapered rays) so it can be tinted and animated freely.
//  ClaudeIndicatorView shows it rotating + pulsing in Anthropic orange while
//  a task is running, and static green for the 15s "done" window.

import SwiftUI

struct ClaudeStarburstShape: Shape {
    // hand-tuned irregularity so the burst reads organic rather than gear-like
    private static let angleJitter:   [Double] = [0.0, 0.10, -0.07, 0.05, -0.12, 0.08, 0.0, -0.06, 0.11, -0.04, 0.07]
    private static let lengthFactors: [Double] = [1.0, 0.82, 0.94, 0.78, 1.0, 0.86, 0.96, 0.80, 0.90, 1.0, 0.84]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let rayCount = Self.lengthFactors.count
        let innerR = r * 0.14

        for i in 0..<rayCount {
            let angle = (Double(i) / Double(rayCount)) * 2 * .pi + Self.angleJitter[i]
            let outerR = r * Self.lengthFactors[i]
            // tapered ray: wider at the base, narrower at the tip
            let baseHalfWidth = r * 0.085
            let tipHalfWidth  = r * 0.035

            let ray = Path { p in
                p.move(to:    CGPoint(x: innerR, y: -baseHalfWidth))
                p.addLine(to: CGPoint(x: outerR, y: -tipHalfWidth))
                p.addQuadCurve(to: CGPoint(x: outerR, y: tipHalfWidth),
                               control: CGPoint(x: outerR + tipHalfWidth * 1.5, y: 0))
                p.addLine(to: CGPoint(x: innerR, y: baseHalfWidth))
                p.closeSubpath()
            }
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: angle)
            path.addPath(ray, transform: transform)
        }
        return path
    }
}

struct ClaudeIndicatorView: View {
    let activity: ClaudeActivity

    private static let anthropicOrange = Color(red: 0.85, green: 0.47, blue: 0.34)
    private static let doneGreen       = Color(red: 0.18, green: 0.84, blue: 0.38)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: activity != .running)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let running = activity == .running
            ClaudeStarburstShape()
                .fill(running ? Self.anthropicOrange : Self.doneGreen)
                .rotationEffect(.degrees(running ? t.truncatingRemainder(dividingBy: 20) * 18 : 0))
                .scaleEffect(running ? 1 + 0.07 * sin(t * 2.4) : 1)
                .animation(.easeOut(duration: 0.35), value: running)
        }
        .frame(width: 18, height: 18)
    }
}
