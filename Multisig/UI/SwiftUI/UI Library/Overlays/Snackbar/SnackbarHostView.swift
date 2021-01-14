//
//  SnackbarHostView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SnackbarHostView<Content: View>: View {
    let content: Content

    @ObservedObject
    var snackbar = App.shared.snackbar

    var body: some View {
        content
            .overlay(
                SnackbarView(isPresented: $snackbar.isPresented,
                             bottomSpacing: $snackbar.bottomEdgeSpacing,
                             content: Text(snackbar.snackbarMessge ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                )
                    .onTapGesture {
                        self.snackbar.hide()
                }
        )
    }
}

struct SnackbarHostViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        SnackbarHostView(content: content)
    }
}

extension View {
    func hostSnackbar() -> some View {
        modifier(SnackbarHostViewModifier())
    }
}

struct SnackbarHostView_Previews: PreviewProvider {
    static var previews: some View {
        SnackbarHostView(content: EmptyView())
    }
}
