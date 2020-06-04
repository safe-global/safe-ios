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
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    @ObservedObject
    var model = LoadableSafeSettingsViewModel()

    var body: some View {
        ZStack {
            if model.safe == nil {
                // so it does not jump when switching Assets <-> Settings in the tap bar
                AddSafeIntroView(padding: .top, -56)
            } else {
                LoadableSafeSettingsView(model: model)
            }
        }
    }
}
