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

    @State var addSafe = false

    var body: some View {
        return NavigationView {
            List {
                AddSafeView(addSafe: $addSafe)
                ForEach(safes) { safe in
                    SafeCellView(safe: safe, isSelected: self.appSettings[0].selectedSafe == safe.address)
                }
            }
            .navigationBarTitle(Text("Switch Safes"), displayMode: .inline)
            .navigationBarItems(leading: closeButton)
            .padding(.top)
        }
        .sheet(isPresented: self.$addSafe) {
            EnterSafeAddressView()
        }
    }

    struct SafeCellView: View {
        var safe: Safe
        var isSelected: Bool

        var body: some View {
            VStack {
                HStack {
                    Identicon(safe.address ?? "")
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading) {
                        Text(safe.name ?? "")
                        Text(safe.address ?? "")
                    }
                    Rectangle() // otherwise this area is not tappable 💩
                        .foregroundColor(.white)
                    if isSelected {
                        Image("ico-check")
                    }
                }
                .frame(height: 46)
                .padding(.horizontal)

                Separator()
            }
            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .onTapGesture {
                print("selected row")
                // TODO: select item, change Database value
            }
        }
    }

    struct Separator: View {
        var body: some View {
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.gnoLightGrey)
        }
    }

    struct AddSafeView: View {
        @Binding var addSafe: Bool

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image("ico-plus-in-circle")
                    Text("Add Safe")
                        .foregroundColor(.gnoHold)
                    Rectangle() // otherwise this area is not tappable 💩
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                Separator()
            }
            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .onTapGesture {
                self.addSafe = true
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
