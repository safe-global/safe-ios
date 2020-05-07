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
    @State private var showsSafeInfo: Bool = false
    @Environment(\.managedObjectContext) var context: CoreDataContext

    var body: some View {
        // Putting the tabview inside a navigation view is the preferred
        // way for Apple. Switching it around (having each tab to have
        // its own navigation view) introduces visual glitch in the
        // status bar (the navigation bar appears beneath the status bar
        // and it looks cropped) - this is seen on a real device (iPhone 6s)
        RootNavigationView {
            TabView(selection: $selection){
                
                AddSafeIntroView()
                    .tabItem {
                        VStack {
                            Image("tab-icon-balances")
                            Text("Balances")
                        }
                }
                .tag(0)
                

                AddSafeIntroView()

                    .tabItem {
                        VStack {
                            Image("tab-icon-transactions")
                            Text("Transactions")
                        }
                }
                .tag(1)
                

                AddSafeIntroView()

                    .tabItem {
                        VStack {
                            Image("tab-icon-settings")
                            Text("Settings")
                        }
                }
                .tag(2)
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
