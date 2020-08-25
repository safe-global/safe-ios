//
//  SwitchSafeView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit

struct SwitchSafeView: View {
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    @FetchRequest(fetchRequest: Safe.fetchRequest().all())
    var safes: FetchedResults<Safe>

    @ObservedObject
    var theme: Theme = App.shared.theme

    var body: some View {
        NavigationView {
            List {
                AddSafeRow()

                ForEach(safes) { safe in
                    SafeRow(safe: safe) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                self.theme.setTemporaryTableViewBackground(UIColor(named: "snowwhite"))
                self.trackEvent(.safeSwitch)
            }
            .onDisappear {
                self.theme.setTemporaryTableViewBackground(nil)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: closeButton)
        }
    }

    var closeButton: some View {
        HStack(spacing: 0) {
            Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                Image.bigXMark
            }
            .frameForTapping(alignment: .leading)

            Text("Switch Safes")
                .headline()
                // otherwise the text is too far to the right
                .padding(.leading, -10)

            Spacer()
        }
        .frameForNavigationBar()
    }
}

// because of the TestCoreDataStack available only in Debug
#if DEBUG

struct SwitchSafeView_Previews: PreviewProvider {
    static var previews: some View {
        SwitchSafeView()
            .environment(\.managedObjectContext, TestCoreDataStack().viewContext)
    }
}

#endif
