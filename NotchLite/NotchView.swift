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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())               // make the whole area hoverable
        .onHover { hovering in
            state.setHovering(hovering)
        }
    }
}
