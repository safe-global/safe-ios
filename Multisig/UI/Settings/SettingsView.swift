//
//  SettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State
    private var selection: Int? = 0

    @State
    private var showImportKeySheet: Bool = false

    var body: some View {
        TopTabView($selection) {
            SafeSettingsContent()
                .gnoTabItem(id: 0) {
                    HStack {
                        Image("ico-safe-settings").frame(width: 24, height: 24)
                        Text("SAFE SETTINGS")
                            .caption()
                            .tracking(0.54)
                    }
                }

            BasicAppSettingsView()
                .gnoTabItem(id: 1) {
                    HStack {
                        Image("ico-app-settings")
                        Text("APP SETTINGS")
                            .caption()
                            .tracking(0.45)
                    }
                }
        }
        .navigationBarTitle("Settings")
        .sheet(isPresented: $showImportKeySheet) {
            EnterSeedPhraseView()
                .hostSnackbar()
        }
        .onReceive(App.shared.viewState.$showImportKeySheet) { newValue in
            self.showImportKeySheet = newValue
        }
    }
}

struct SettingsTopTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
