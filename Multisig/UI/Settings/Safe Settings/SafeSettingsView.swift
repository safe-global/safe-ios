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

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>
    
    var body: some View {
        ZStack {
            if selected.first == nil {
                // so it does not jump when switching Assets <-> Settings in the tap bar
                AddSafeIntroView(padding: .top, -56)
            } else {
                LoadableSafeSettingsView(safe: selected.first!)
                    .environment(\.managedObjectContext, self.context)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SafeSettingsView()
    }
}
