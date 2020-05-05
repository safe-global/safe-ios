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
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext

    @FetchRequest(fetchRequest: AppSettings.settings())
    var appSettings: FetchedResults<AppSettings>
    
    @State
    var updateID = UUID()
    var didSave = NotificationCenter.default
        .publisher(for: .NSManagedObjectContextDidSave,
                   object: CoreDataStack.shared.viewContext)
        .receive(on: RunLoop.main)

    @State
    var safe: Safe?
    
    @State
    var showsLink: Bool = false
    
    var body: some View {
        return VStack (alignment: .center, spacing: 18){
            Identicon(safe?.address ?? "")
                .frame(width: 56, height: 56)

            Text(safe?.name ?? "")
                .font(Font.gnoBody.weight(.medium))
                .multilineTextAlignment(.center)

            HStack (alignment: .top, spacing: 2) {
                
                Button(action: {
                    UIPasteboard.general.string = self.safe?.address ?? ""
                }) {
                    AddressText(safe?.address ?? "")
                    .multilineTextAlignment(.center)
                }
                
                Button(action: { self.showsLink.toggle()}) {
                    Image("icon-external-link")
                }.foregroundColor(.gnoHold)
                .frame(width: 24, height: 24)
                .sheet(isPresented: $showsLink, content: browseSafeAddress)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)

            Text(safe?.ensName ?? "")
                .font(Font.gnoBody.weight(.medium))
                .multilineTextAlignment(.center)

            QRView(value: safe?.address ?? "").frame(width: 124, height: 124)
        }.cardShadowTooltip()
        .id(updateID)
        .onReceive(appSettings.publisher.first()) { settings in
            self.safe = Safe.selected(settings)
        }
        .onReceive(didSave, perform: { _ in self.updateID = UUID() })
    }
    
    func browseSafeAddress() -> some View {
        let safeURL = URL(string: "https://etherscan.io/address/" + (safe?.address ?? ""))!
        return SafariViewController(url: safeURL)
    }
}

struct SafeInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoView()
    }
}
