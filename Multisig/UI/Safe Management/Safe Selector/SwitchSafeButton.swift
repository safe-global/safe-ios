//
//  SwitchSafeButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SwitchSafeButton: View {

    @Environment(\.managedObjectContext) var context: CoreDataContext

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>

    @State var showsSwitchSafe: Bool = false

    var body: some View {
        ZStack {
            if selected.first == nil {
                EmptyView()
            } else {
                Button(action: { self.showsSwitchSafe.toggle() }) {
                    Image.chevronDownCircle
                }
                .frameForTapping(alignment: .trailing)
                .sheet(isPresented: $showsSwitchSafe) {
                    SwitchSafeView()
                        .environment(\.managedObjectContext, self.context)
                        .snackbarBottomPadding()
                        .hostSnackbar()

                }

            }
        }
    }

}


struct SwitchSafeButton_Previews: PreviewProvider {
    static var previews: some View {
        SwitchSafeButton()
    }
}
