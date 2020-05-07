//
//  SafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeSettingsView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>
    
    @ObservedObject
    var model = SafeSettingsViewModel()
    
    @State
    var updateID = UUID()
    var didSave = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: CoreDataStack.shared.viewContext)
        .receive(on: RunLoop.main)

    @State
    var safe: Safe?
    
    @State
    var showEditSafeName: Bool = false
    
    @State
    private var showDeleteSafeConfirmation: Bool = false
    var body: some View {
        let safe = selectedSafe.first
        return ZStack(alignment: .center) {
            if model.isResolving ?? false {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            }
            else {
                List {
                    Section(header: ListSectionHeader(text:"SAFE NAME")) {
                        NavigationLink(destination: EditSafeNameView(address: safe?.address ?? "", name: safe?.name ?? "")) {
                            BodyText(safe?.name ?? "")
                        }
                    }
                    
                    Section(header: ListSectionHeader(text: "REQUIRED CONFIRMATIONS")) {
                        BodyText("\(0) out of \(model.info?.owners.count ?? 0)")
                    }
                    
                    Section(header: ListSectionHeader(text: "OWNER ADDRESSES")) {
                        ForEach(model.info?.owners ?? [], id: \.self, content: { owner in
                            AddressCell(address: owner)
                        })
                    }
                    
                    Section(header: ListSectionHeader(text: "CONTRACT VERSION")) {
                        SafeCell(safe: safe!)
                    }
                    
                    Section(header: ListSectionHeader(text: "ENS NAME")) {
                        LoadableENSNameText(safe: safe!, placeholder: "Not Set")
                    }
                    
                    
                    Section(header: ListSectionHeader(text: " ")) {
                        NavigationLink(destination: SafeAdvancedSettingsView(safe: safe,model: model)) {
                            BodyText("Advanced")
                        }
                    }
                }
            }
        }.onAppear(perform: {
            if self.safe == nil {
                self.safe = self.selectedSafe.first!
            }
            if self.model.info == nil && !(self.model.isResolving ?? false) {
                self.model.address = self.safe?.address ?? ""
                self.model.resolve()
            }
        })
    }
    
    
}

struct SafeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SafeSettingsView()
    }
}
