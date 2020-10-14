//
//  MainTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext)
    var context: CoreDataContext

    @State
    private var selection = ViewStateMode.balances

    @State
    private var showsSafesList = false

    var body: some View {
        TabView(selection: $selection) {
            MainContentView(AssetsView())
                .tabItem {
                    VStack {
                        Image("tab-icon-balances")
                        Text("Assets")
                    }
                }
                .tag(ViewStateMode.balances)

            MainContentView(TransactionsTabView())
                .tabItem {
                    VStack {
                        Image("tab-icon-transactions")
                        Text("Transactions")
                    }
                }
                .tag(ViewStateMode.transactions)

            MainContentView(SettingsView())
                .tabItem {
                    VStack {
                        Image("tab-icon-settings")
                        Text("Settings")
                    }
                }
                .tag(ViewStateMode.settings)
        }
        .accentColor(.gnoHold)
        .sheet(isPresented: $showsSafesList) {
            SwitchSafeView()
                .environment(\.managedObjectContext, self.context)
                .hostSnackbar()
        }
        .onReceive(App.shared.viewState.$showsSafesList) { newValue in
            self.showsSafesList = newValue
        }
        .onReceive(App.shared.viewState.$state) { newValue in
            self.selection = newValue
        }
    }
}
