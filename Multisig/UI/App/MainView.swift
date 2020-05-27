//
//  MainView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 27.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct MainView: View {
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

                BottomTabView($viewState.state) {
                    AssetsView()
                        .environment(\.managedObjectContext, context)
                        .gnoTabItem(id: ViewStateMode.balances) {
                            VStack {
                                Image("tab-icon-balances")
                                Text("Assets")
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
