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

    var body: some View {
        TopTabView($selection) {
            SafeSettingsView()
                .gnoTabItem(id: 0) {
                    HStack {
                        Image("ico-safe-settings")
                        Text("SAFE SETTINGS")
                            .font(Font.gnoCaption1)
                            .tracking(0.54)
                    }
                }

            BasicAppSettingsView()
                .gnoTabItem(id: 1) {
                    HStack {
                        Image("ico-app-settings")
                        Text("APP SETTINGS")
                            .font(Font.gnoCaption1)
                            .tracking(0.45)
                    }
                }
        }
    }
}

struct SettingsTopTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
