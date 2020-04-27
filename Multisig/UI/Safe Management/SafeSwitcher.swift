//
//  SafeSwitcher.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData
import Combine

struct SafeSwitcher: View {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @FetchRequest(
        entity: Safe.entity(),
        sortDescriptors: [])
    var safes: FetchedResults<Safe>

    // workaround SwiftUI not updating the view whenever the
    // context is changing from another context. Changing this variable
    // triggers new fetch request.
    @State
    var updateID = UUID()
    var didSave = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave,
                                                       object: CoreDataStack.shared.persistentContainer.viewContext)

    var body: some View {
        List(safes.filter { $0.address != nil }, id: \.self) { safe in
            HStack(spacing: 12) {
                Identicon(safe.address!).frame(width: 36, height: 36)

                VStack(alignment: .leading) {
                    BodyText(label: safe.name ?? "Unnamed Safe")

                    AddressText(safe.address!)
                }
                .frame(height: 36)
            }
        }
        .id(updateID)
        .navigationBarTitle("Safes")
        .navigationBarItems(leading: closeButton, trailing: removeAllButton)
        .onReceive(didSave, perform: { _ in self.updateID = UUID() })
    }

    var closeButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
        }
    }

    var removeAllButton: some View {
        Button("Remove All") {
            // TODO: Debug only, delete.
            let c = CoreDataStack.shared.persistentContainer.viewContext

            let allReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Safe")
            let delReq = NSBatchDeleteRequest(fetchRequest: allReq)

            let settings = AppSettings.getOrCreate(context: c)
            settings.selectedSafe = nil

            do {
                try c.save()
                try c.execute(delReq) // does not change the context!
                c.reset() // change the context
            } catch {
                print("Clear All Error", error)
            }
        }
    }
}

struct SafeSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        SafeSwitcher()
    }
}
