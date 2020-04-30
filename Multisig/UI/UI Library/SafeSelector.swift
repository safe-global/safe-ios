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

fileprivate var safeSub: AnyCancellable?

struct SafeSelector: View {

    private let height: CGFloat = 116

    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    @FetchRequest(fetchRequest: AppSettings.settings())
    var appSettings: FetchedResults<AppSettings>

    // workaround to listen to the changes of the Safe object (name, address)
    @State
    var updateID = UUID()

    @State
    var showInfo: Bool = false

    @State
    var showSafes: Bool = false

    var body: some View {
        let safe = appSettings.first?.selectedSafe
        safeSub?.cancel()
        if let safe = safe {
            // subscribe on safe properties updates (like Name)
            // FetchRequest triggers view update only if selected Safe is changed
            safeSub = safe.objectWillChange
                .receive(on: RunLoop.main)
                .sink(receiveValue: { _ in
                    self.updateID = UUID()
                })
        }
        return HStack(alignment: .center, spacing: 0) {
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
            Image(systemName: "chevron.down.circle")
                .foregroundColor(.gnoMediumGrey)
                .font(Font.body.weight(.semibold))
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
        let context = TestCoreDataStack().persistentContainer.viewContext
        return SafeSelector().environment(\.managedObjectContext, context)
    }
}
