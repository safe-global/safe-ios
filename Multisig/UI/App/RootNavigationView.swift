//
//  RootNavigationView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct RootNavigationView<Content>: View where Content: View {

    @Environment(\.managedObjectContext) var context: CoreDataContext

    @State private var showsSafeInfo: Bool = false

    private var content: Content

    @inlinable public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationView {
            content
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: selectButton,
                                trailing: switchButton)
        }
        .accentColor(.gnoHold)
        .background(Color.gnoWhite)
        .overlay(
            PopupView(isPresented: $showsSafeInfo) {
                SafeInfoView().environment(\.managedObjectContext, context)
            }
        )
    }

    var selectButton: some View {
        SelectedSafeButton(showsSafeInfo: $showsSafeInfo)
            .environment(\.managedObjectContext, context)
    }

    var switchButton: some View {
        SwitchSafeButton().environment(\.managedObjectContext, context)
    }

}
