//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeInfoView: View {
    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    
    var body: some View {
        let safe = appSettings[0].selectedSafe

        return VStack (alignment: .center, spacing: 18){
            Identicon(safe?.address ?? "")
                .frame(width: 56, height: 56)

            Text(safe?.name ?? "")
                .font(Font.gnoBody.weight(.medium))
                .multilineTextAlignment(.center)

            HStack (alignment: .top, spacing: 12) {
                AddressText(safe?.address ?? "")
                    .multilineTextAlignment(.center)

                Button(action: {
                    UIPasteboard.general.string = safe?.address ?? ""
                }) {
                    Image("icon-external-link")
                }.foregroundColor(.gnoHold).frame(width: 24, height: 24)
            }
            .padding(.leading, 60)
            .padding(.trailing, 24)

            Text(safe?.ensName ?? "")
                .font(Font.gnoBody.weight(.medium))
                .multilineTextAlignment(.center)

            QRView(value: safe?.address ?? "").frame(width: 124, height: 124)
        }.cardShadowTooltip()
    }
}

struct SafeInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoView().frame(width: 340, height: 340)
    }
}
