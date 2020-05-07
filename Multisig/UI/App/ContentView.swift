//
//  ContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var context: CoreDataContext

    @State private var selection = 0
    @State var showsInfo: Bool = false
    
    var body: some View {
        // FIXME: Note, that the tabs "blink" on switching.
        // This is a performance issue to be fixed.
        // see https://forums.developer.apple.com/thread/124475
        TabView(selection: $selection){
            TabItemView(showsSafeInfo: $showsInfo) {
                AddSafeIntroView()
            }
            .tabItem {
                VStack {
                    Image("tab-icon-balances")
                    Text("Balances")
                }
            }
            .tag(0)

            TabItemView(showsSafeInfo: $showsInfo) {
                AddSafeIntroView()
            }
            .tabItem {
                VStack {
                    Image("tab-icon-transactions")
                    Text("Transactions")
                }
            }
            .tag(1)

            TabItemView(showsSafeInfo: $showsInfo) {
                SettingsView()
            }
            .tabItem {
                VStack {
                    Image("tab-icon-settings")
                    Text("Settings")
                }
            }
            .tag(2)
        }
        .accentColor(.gnoHold)
        .background(Color.gnoWhite)
        .overlay(
            PopupView(isPresented: $showsInfo) {
                SafeInfoView().environment(\.managedObjectContext, context)
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
