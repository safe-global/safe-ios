//
//  ContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var context: CoreDataContext

    @ObservedObject
    var viewState = App.shared.viewState

    @State
    private var showsSafeInfo: Bool = false

    private let headerHeight: CGFloat = 116

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SafeHeaderView(showsSafeInfo: $showsSafeInfo)
                    .environment(\.managedObjectContext, context)
                    .frame(height: headerHeight)
                    .zIndex(100)

                GNOTabView($viewState.state) {

                    TempAssets()
                        .environment(\.managedObjectContext, context)
                        .gnoTabItem(id: ViewStateMode.balanaces) {
                            VStack {
                                Image("tab-icon-balances")
                                Text("Balances")
                            }
                        }

                    AddSafeIntroView()
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
                // without it, the NavigationViewController overlays the
                // invisible navigation bar on top of everything else,
                // and the header becomes untappable.
                // Hiding/showing the navigation bar to workaround that.
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(viewState.hidesNavbar)
                .hidesSystemNavigationBar(true)
            }
            .edgesIgnoringSafeArea(.top)
        }
        .accentColor(.gnoHold)
        .background(Color.gnoWhite)
        .overlay(
            PopupView(isPresented: $showsSafeInfo) {
                SafeInfoView().environment(\.managedObjectContext, context)
            }
        )
    }
}

struct TempAssets: View {
    @Environment(\.managedObjectContext)
    var context: CoreDataContext

    @State var selection: Int? = 0

    var body: some View {
        TopTabView($selection) {
            AssetsOrAddSafeIntroView()
                .environment(\.managedObjectContext, context)
                .gnoTabItem(id: 0) {
                    HStack {
                        Image(systemName: "circle.fill")
                        Text("Coins")
                    }
                }

            Text("Coming soon")
                .gnoTabItem(id: 1) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Collectibles")
                    }
                }
        }
        .background(Color.gnoWhite)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
