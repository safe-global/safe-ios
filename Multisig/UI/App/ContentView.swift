//
//  ContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov. on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    @State private var selection = 0
    @State var showsInfo: Bool = false
    @State var showsSwitchSafe: Bool = false
    
    var body: some View {
        TabView(selection: $selection){
            NavigationView {
                AddSafeIntroView(showsSafeInfo: $showsInfo,
                                 showsSwitchSafe: $showsSwitchSafe)
            }
            .tabItem {
                VStack {
                    Image("tab-icon-balances")
                    Text("Balances")
                }
            }
            .tag(0)

            NavigationView {
                Text("Transactions")
                    .font(.gnoNormal)
            }
            .tabItem {
                VStack {
                    Image("tab-icon-transactions")
                    Text("Transactions")
                }
            }
            .tag(1)

            NavigationView {
                Text("Settings")
                    .font(.gnoNormal)
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
        .overlay(
            PopupView(isPresented: $showsInfo) {
                SafeInfoView()
            }
        )
        .sheet(isPresented: $showsSwitchSafe) {
            SwitchSafeView().environment(\.managedObjectContext, self.context)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
