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

    @State var acceptedTerms = AppSettings.hasAcceptedTerms()

    var body: some View {
        ZStack {
            if acceptedTerms {
                MainView().environment(\.managedObjectContext, context)
            } else {
                LaunchView(acceptedTerms: $acceptedTerms)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
