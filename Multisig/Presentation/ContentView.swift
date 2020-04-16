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

    let selector = SafeSelector()
 
    var body: some View {
        VStack(spacing: 0) {

            selector.zIndex(1)

            TabView(selection: $selection){

                AddSafeIntro()
                    .padding(.top, -selector.height)
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
            .accentColor(.gnoHold)

        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
