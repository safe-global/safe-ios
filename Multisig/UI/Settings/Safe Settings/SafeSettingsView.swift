//
//  SelectedSafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeSettingsView: View {
    var model: SafeSettingsViewModel?

    init(safe: Safe?) {
        if let safe = safe {
            model = SafeSettingsViewModel(safe: safe)
        }
    }

    var body: some View {
        ZStack {
            if model == nil {
                // so it does not jump when switching Assets <-> Settings in the tap bar
                AddSafeIntroView(padding: .top, -56).onAppear {
                    self.trackEvent(.settingsSafeNoSafe)
                }
            } else {
                ZStack(alignment: .center) {
                    Rectangle()
                        .edgesIgnoringSafeArea(.all)
                        .foregroundColor(Color.gnoWhite)

                    LoadableView(BasicSafeSettingsView(model: model!))
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SafeSettingsView(safe: nil)
    }
}
