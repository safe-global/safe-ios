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
//            VStack(spacing: 0) {
//                SafeHeaderView(showsSafeInfo: $showsSafeInfo)
//                    .frame(height: ScreenMetrics.safeHeaderHeight)

            content
                .navigationBarItems(leading: selectButton, trailing: switchButton)
//            }
//            .edgesIgnoringSafeArea(.top)
        }
        .overlay(
            PopupView(isPresented: $showsSafeInfo) {
                SafeInfoView()
            }
        )
        .hostSnackbar()
    }

    var selectButton: some View {
        SelectedSafeButton(showsSafeInfo: $showsSafeInfo)
    }

    var switchButton: some View {
        SwitchSafeButton()
    }

}
