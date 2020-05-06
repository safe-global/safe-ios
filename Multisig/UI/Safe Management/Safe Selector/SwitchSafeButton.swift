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

    @State var showsSwitchSafe: Bool = false

    var body: some View {
        Button(action: { self.showsSwitchSafe.toggle() }) {
            Image(systemName: "chevron.down.circle")
                .foregroundColor(.gnoMediumGrey)
                .font(Font.body.weight(.semibold))
                // increases tappable area
                .frame(minWidth: 60, idealHeight: 44, alignment: .trailing)
        }
        .padding(.bottom)
        .sheet(isPresented: $showsSwitchSafe) {
            SwitchSafeView()
                .environment(\.managedObjectContext, self.context)
        }
    }

}


struct SwitchSafeButton_Previews: PreviewProvider {
    static var previews: some View {
        SwitchSafeButton()
    }
}
