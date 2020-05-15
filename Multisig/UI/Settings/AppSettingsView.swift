//
//  AppSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AppSettingsView: View {
    var body: some View {
        List {
            NavigationLink("Get In Touch", destination: GetInTouchView())
            NavigationLink("Advanced", destination: AdvancedAppSettings())
        }
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
