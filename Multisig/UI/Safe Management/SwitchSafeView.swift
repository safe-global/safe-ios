//
//  SwitchSafeView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SwitchSafeView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @FetchRequest(fetchRequest: Safe.allSafes()) var safes: FetchedResults<Safe>
    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>

    @State var addSafe = false
    var body: some View {
        return NavigationView {
            List {
                AddSafeView(addSafe: $addSafe)
                ForEach(safes) { safe in
                    SafeCellView(safe: safe, appSettings: self.appSettings[0], presentationMode: self.presentationMode)
                }
            }
            .navigationBarTitle(Text("Switch Safes"), displayMode: .inline)
            .navigationBarItems(leading: closeButton)
            .padding(.top)
        }
        .sheet(isPresented: self.$addSafe) {
            NavigationView {
                EnterSafeAddressView()
            }
        }
    }

    struct SafeCellView: View {
        var safe: Safe
        @ObservedObject var appSettings: AppSettings
        var presentationMode: Binding<PresentationMode>
        var body: some View {
            VStack {
                HStack {
                    Identicon(safe.address ?? "")
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading) {
                        Text(safe.name ?? "")
                        Text(safe.address ?? "")
                    }
                    Spacer()
                    if appSettings.selectedSafe == safe.address {
                        Image("ico-check")
                    }
                }
                .frame(height: 46)
                .padding(.horizontal)

                Separator()
            }
            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .background(Rectangle().foregroundColor(.white))
            .onTapGesture {
                self.appSettings.selectedSafe = self.safe.address
                self.presentationMode.wrappedValue.dismiss()
                CoreDataStack.shared.saveContext()
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
                }
                .padding(.horizontal)

                Separator()
            }
            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .background(Rectangle().foregroundColor(.white))
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
