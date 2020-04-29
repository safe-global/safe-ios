//
//  SafeSelector.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData
import Combine

struct SafeSelector: View {

    private let height: CGFloat = 116

    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    @FetchRequest(fetchRequest: AppSettings.settings())
    var appSettings: FetchedResults<AppSettings>

    // workaround to listen to the changes of the Safe object (name, address)
    @State
    var updateID = UUID()
    var didSave = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: CoreDataStack.shared.viewContext)
        .receive(on: RunLoop.main)

    @State
    var safe: Safe?

    @State
    var showInfo: Bool = false

    @State
    var showSafes: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if safe == nil {
                notSelectedView
            } else {
                currentSafeButton(safe)
                Spacer()
                switchSafeButton
            }
        }
        .id(updateID)
        .frame(height: height, alignment: .bottom)
        .background(backgroundView)
        .onReceive(appSettings.publisher.first()) { settings in
            self.safe = settings.selectedSafe
        }
        .onReceive(didSave, perform: { _ in self.updateID = UUID() })
    }

    var notSelectedView: some View {
        Group {
            Image("safe-selector-not-selected-icon")
                .padding()
            Text("No Safe loaded")
                .font(Font.gnoBody.weight(.semibold))
                .foregroundColor(Color.gnoMediumGrey)
            Spacer()
        }
    }

    func currentSafeButton(_ safe: Safe?) -> some View {
        Button(action: { self.showInfo.toggle() }) {
            SafeCell(safe: safe)
        }
        .sheet(isPresented: self.$showInfo) {
            SafeInfoView().environment(\.managedObjectContext, self.context)
        }
    }

    var switchSafeButton: some View {
        Button(action: { self.showSafes.toggle() }) {
            Image("ico-circle-down")
        }
        .foregroundColor(.gnoMediumGrey)
        .frame(width: 20, height: 20)
        .padding()
        .sheet(isPresented: self.$showSafes) {
            SwitchSafeView().environment(\.managedObjectContext, self.context)
        }
    }

    var backgroundView: some View {
        Rectangle()
        .foregroundColor(Color.gnoSnowwhite)
        .cardShadowTooltip()
    }
}

struct SafeSelector_Previews: PreviewProvider {
    static var previews: some View {
        SafeSelector()
    }
}
