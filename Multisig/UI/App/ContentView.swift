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

    @State private var selection = 0

    @State
    var showInfo: Bool = false
    
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext
    
    var body: some View {
        ZStack(alignment: .center)  {
            VStack(spacing: 0) {
                SafeSelector(showInfoHandler: showHide)
                    .zIndex(1)

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
            
            if showInfo {
                PopupContainer(content: AnyView(SafeInfoView().environment(\.managedObjectContext, self.context))
                            , dismissHandler: showHide)
            }
        }
    }
    
    func showHide() {
        withAnimation(.easeInOut) {
            self.showInfo.toggle()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
