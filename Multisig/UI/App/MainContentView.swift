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

    @Environment(\.managedObjectContext)
    var context: CoreDataContext

    private let content: Content

    init(_ content: Content) {
        self.content = content
    }

    var body: some View {
        NavigationView {
            content
                .environment(\.managedObjectContext, self.context)
                .navigationBarItems(leading: selectButton, trailing: switchButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .overlay(
            PopupView(isPresented: $showsSafeInfo) {
                SafeInfoView()
            }
        )
        .hostSnackbar()
    }

    var selectButton: some View {
        SelectedSafeButton(showsSafeInfo: $showsSafeInfo)
            .environment(\.managedObjectContext, self.context)

    }

    var switchButton: some View {
        SwitchSafeButton()
            .environment(\.managedObjectContext, self.context)

    }

}
