//
//  TopTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SettingsTopTabView: View {

    var body: some View {
        TopTabView {
            SelectedSafeSettingsView()
                .topTabItem {
                    HStack {
                        Image("ico-safe-settings")

                        Text("SAFE SETTINGS").font(Font.gnoFootnote.bold())
                    }
                }

            AppSettingsView()
                .topTabItem {
                    HStack {
                        Image("ico-app-settings")

                        Text("APP SETTINGS").font(Font.gnoFootnote.bold())
                    }
                }
        }
    }
}

struct SettingsTopTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTopTabView()
    }
}
