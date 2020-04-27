//
//  ContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @State private var showSafeSelectorSheet: Bool = false
    @State private var activeSheet: SafeSelectorActiveOption = .none
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>
    var body: some View {
        return VStack(spacing: 0) {
            SafeSelector(showSheet: $showSafeSelectorSheet, activeSheet: $activeSheet).zIndex(1).environment(\.managedObjectContext, context)
            .sheet(isPresented: self.$showSafeSelectorSheet) {
                //TODO: handle show safe info screen
                SwitchSafeView().environment(\.managedObjectContext, self.context)
            }

            TabView(selection: $selection){

                AddSafeIntroView()
                    .padding(.top, -116)
                    .tabItem {
                        VStack {
                            Image("tab-icon-balances")
                            Text("Balances")
                        }
                }
                .tag(0)

                Text("Transactions")
                    .font(.gnoNormal)
                    .tabItem {
                        VStack {
                            Image("tab-icon-transactions")
                            Text("Transactions")
                        }
                }
                .tag(1)

                Text("Settings")
                    .font(.gnoNormal)
                    .tabItem {
                        VStack {
                            Image("tab-icon-settings")
                            Text("Settings")
                        }
                }
                .tag(2)

            }
        }
        .accentColor(.gnoHold)
        .edgesIgnoringSafeArea(.top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
