//
//  SwitchSafeView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SwitchSafeView: View {
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @FetchRequest(fetchRequest: Safe.allSafes()) var safes: FetchedResults<Safe>
    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>

    var body: some View {
        NavigationView() {
            List(safes) { safe in
                SafeCellView(safe: safe, isSelected: self.appSettings[0].selectedSafe == safe.address)
            }
            .navigationBarTitle(Text("Switch Safes"), displayMode: .inline)
            .navigationBarItems(leading: closeButton)
        }
        .shadow(color: Color.black, radius: 1, x: 0, y: 0)
    }

    struct SafeCellView: View {
        var safe: Safe
        var isSelected: Bool

        var body: some View {
            HStack {
                Identicon(safe.address ?? "")
                    .frame(width: 32)
                    .padding(.trailing)
                VStack(alignment: .leading) {
                    Text(safe.name ?? "")
                    Text(safe.address ?? "")
                }
                Spacer()
                if isSelected {
                    Image("ico-check")
                }
            }
        }
    }

    var closeButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Image("ico-cross")
        })
        .accentColor(.gnoMediumGrey)
    }
}

#if DEBUG
struct SwitchSafeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = TestCoreDataStack().persistentContainer.viewContext
        let appSettings = AppSettings(context: context)
        appSettings.selectedSafe = "0x3"
        for i in 1...5 {
            let safe = Safe(context: context)
            safe.name = "Safe \(i)"
            safe.address = "0x\(i)"
        }
        return SwitchSafeView()
            .environment(\.managedObjectContext, context)
    }
}
#endif
