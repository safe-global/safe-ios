//
//  TopTabView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SettingsTopTabView: View {

    @State var selection: Int = 0

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Safe Settings") { self.selection = 0 }
                Spacer()
                Divider()
                Spacer()
                Button("App Settings") { self.selection = 1 }
                Spacer()
            }
            .frame(height: 60)

            ZStack {
                if selection == 0 {
                    SelectedSafeSettingsView()
                } else {
                    BasicAppSettingsView()
                }
            }
        }
    }
}

struct TopTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTopTabView()
    }
}
