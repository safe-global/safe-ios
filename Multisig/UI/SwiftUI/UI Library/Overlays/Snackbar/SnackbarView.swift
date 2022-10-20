//
//  SnackbarView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

enum SnackbarViewMetrics {
    static let textPadding = CGSize(width: Spacing.medium, height: 14)
    static let cornerRadius: CGFloat = 8
    static let screenPadding = CGSize(width: Spacing.medium, height: 10)
    static let offscreenOffset: CGFloat = 300
}

struct SnackbarView<T: View>: View {

    @Binding
    var isPresented: Bool

    // this is to dynamically react to the bottom bar appearance
    @Binding
    var bottomSpacing: CGFloat

    var content: T

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().opacity(0)

            VStack(alignment: .leading) {
                content
            }
            .padding(.horizontal, SnackbarViewMetrics.textPadding.width)
            .padding(.vertical, SnackbarViewMetrics.textPadding.height)
            .frame(maxWidth: .infinity)
            .foregroundColor(.backgroundSecondary)
            .background(Color.labelPrimary)
            .cornerRadius(SnackbarViewMetrics.cornerRadius)
            .padding(.horizontal, SnackbarViewMetrics.screenPadding.width)
            .offset(y: self.isPresented ?
                -self.bottomSpacing : SnackbarViewMetrics.offscreenOffset)
        }
        .opacity(isPresented ? 1 : 0)
        .animation(.spring())
    }

}
