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

    @FetchRequest(fetchRequest: Safe.fetchRequest().all())
    var safes: FetchedResults<Safe>

//    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>

    @State var addSafe = false
    var body: some View {
        return NavigationView {
            List {
                AddSafeView(addSafe: $addSafe)
                ForEach(safes) { safe in
//                    SafeCellView(safe: safe, appSettings: self.appSettings[0], presentationMode: self.presentationMode)
                    Text("")
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
//        @ObservedObject var appSettings: AppSettings
        var presentationMode: Binding<PresentationMode>
        var body: some View {
            VStack {
                HStack {
                    SafeCell(safe: safe)
                    Spacer()
//                    if appSettings.selectedSafe == safe {
                        Image(systemName: "checkmark")
                            .font(Font.body.weight(.regular))
                            .foregroundColor(.gnoHold)
//                    }
                }
                .frame(height: 46)
                .padding(.trailing)

                Separator()
            }
            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
            .background(Rectangle().foregroundColor(.white))
            .onTapGesture {
//                self.appSettings.selectedSafe = self.safe
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
                    Image(systemName: "plus.circle")
                        .foregroundColor(.gnoHold)
                        .font(Font.body.weight(.medium))
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
            Image(systemName: "xmark")
                .foregroundColor(.gnoMediumGrey)
                .font(Font.title.weight(.thin))
        })
        .accentColor(.gnoMediumGrey)
    }
}

struct SwitchSafeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = TestCoreDataStack().persistentContainer.viewContext
        for i in 1...4 {
            let safe = Safe(context: context)
            safe.name = "Safe \(i)"
            safe.address = "0x\(i)"
        }
        let safe = Safe(context: context)
        safe.name = "Safe 5"
        safe.address = "0x55555555555"
//        let appSettings = AppSettings(context: context)
//        appSettings.selectedSafe = safe

        return SwitchSafeView()
            .environment(\.managedObjectContext, context)
    }
}
