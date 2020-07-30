//
//  SnackbarBottomPaddingModifier.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct SnackbarBottomPaddingModifier: ViewModifier {
    let adjustment: CGFloat

    func body(content: Content) -> some View {
        content
        .onAppear {
            App.shared.snackbar.setBottomPadding(self.adjustment)
        }
        .onDisappear {
            App.shared.snackbar.resetBottomPadding()
        }
    }
}

extension View {
    func snackbarBottomPadding(_ value: CGFloat = ScreenMetrics.aboveBottomEdge) -> some View {
        modifier(SnackbarBottomPaddingModifier(adjustment: value))
    }
}
