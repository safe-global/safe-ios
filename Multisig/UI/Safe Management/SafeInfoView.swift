//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

extension Safe {

    var hasAddress: Bool { address?.isEmpty == false }
    var displayAddress: String { address! }

    var displayName: String { name.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled Safe" }

//    var displayENSName: String { ensName ?? "" }

}

struct SafeInfoView: View {

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    var body: some View {
        Group {
            if selectedSafe.first == nil {
                BodyText(label: "No Safe is selected")
            } else {
                SafeInfoContentView(safe: selectedSafe.first!)
            }
        }
    }
}

struct SafeInfoContentView: View {

    @ObservedObject
    var safe: Safe

    @State
    var showsBrowser: Bool = false

    var body: some View {
        VStack (alignment: .center, spacing: 18) {
            Identicon(safe.address)
                .frame(width: 56, height: 56)

            BodyText(label: safe.displayName)

            addressView

//            if !safe.ensName.isEmpty {
//                BodyText(label: safe.ensName)
//            }

            QRView(value: safe.address)
                .frame(width: 150, height: 150)
        }
        .multilineTextAlignment(.center)
    }

    var addressView: some View {
        HStack {
            Button(action: {
                UIPasteboard.general.string = self.safe.address
            }) {
                AddressText(safe.address!)
                    .multilineTextAlignment(.center)
            }

            Button(action: { self.showsBrowser.toggle() }) {
                Image("icon-external-link")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gnoHold)
            }
            .frame(width: 44, height: 44)

        }
        // these two lines make sure that the alignment will be by
        // the addreses text's center, and
        .padding([.leading, .trailing], 44)
        // that 'link button' will be visually attached to the trailnig
        .padding(.trailing, -44)

//        .sheet(isPresented: $showsBrowser) {
//            SafariViewController(url: self.safe.browseURL)
//        }
    }
    
}

struct SafeInfoContentView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoContentView(safe: Safe())
        .padding()
    }
}
