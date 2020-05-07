//
//  SettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

       // workaround to listen to the changes of the Safe object (name, address)
   @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
   var selected: FetchedResults<Safe>
    
    var body: some View {
        SafeSettingsView(safe: selected.first!).environment(\.managedObjectContext, self.context)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
