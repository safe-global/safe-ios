//
//  MainView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct MainContentView<Content: View>: View {
    @State
    private var showsSafeInfo: Bool = false

    private let content: Content

    init(_ content: Content) {
        self.content = content
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SafeHeaderView(showsSafeInfo: $showsSafeInfo)
                    .frame(height: ScreenMetrics.safeHeaderHeight)

                content
            }
            .edgesIgnoringSafeArea(.top)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .overlay(
                PopupView(isPresented: $showsSafeInfo) {
                    SafeInfoView()
                }
            )
            .hostSnackbar()
        }
    }
}
