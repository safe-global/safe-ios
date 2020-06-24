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

    // NOTE: the local/global state to prevent
    // view from redrawing itself when the global state
    // changes due to the change in the selected tab,
    // which causes complete redraw and has a side effect of
    // unnecessary network requests in the sub views

    // Other alternatives that did not work:
    //  - observing global state and using it in the BottomTabView selector
    //  - just the local state, since we want to change the tab
    //    from some other place in the app
    @State
    var localSelection: ViewStateMode? = ViewStateMode.balances

    var globalSelection = App.shared.viewState

    let tabBarSpacing: CGFloat = 8

    var body: some View {
        BottomTabView($localSelection) {
            AssetsView()
                .environment(\.managedObjectContext, context)
                .gnoTabItem(id: ViewStateMode.balances) {
                    VStack {
                        Image("tab-icon-balances")
                        Text("Assets")
                    }
                }

            TransactionsView()
                .gnoTabItem(id: ViewStateMode.transactions) {
                    VStack {
                        Image("tab-icon-transactions")
                        Text("Transactions")
                    }
                }

            SettingsView()
                .gnoTabItem(id: ViewStateMode.settings) {
                    VStack {
                        Image("tab-icon-settings")
                        Text("Settings")
                    }
                }
        }
        .onAppear {
            // this adjusts the snack bar position
            App.shared.viewState.bottomBarHeight =
                BottomTabViewMetrics.tabBarHeight + self.tabBarSpacing
        }
        .onDisappear {
            App.shared.viewState.bottomBarHeight = 0
        }
        .onReceive(globalSelection.$state) { newValue in
            if newValue != self.localSelection {
                self.localSelection = newValue
            }
        }
    }
}
