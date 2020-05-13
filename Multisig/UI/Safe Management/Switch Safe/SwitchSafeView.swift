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
                UITableView.appearance().backgroundColor = nil
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: closeButton)
        }
    }

    var closeButton: some View {
        Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
            HStack(spacing: 32) {
                Image(systemName: "xmark")
                    .font(Font.gnoNormal)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gnoMediumGrey)

                BoldText("Switch Safes")

                Spacer()
            }
        }
    }
}

struct SwitchSafeView_Previews: PreviewProvider {
    static var previews: some View {
        SwitchSafeView()
            .environment(\.managedObjectContext, TestCoreDataStack.context)
    }
}
