//
//  CenteredAddressWithLink.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct CenteredAddressWithLink: View {

    @ObservedObject
    var safe: Safe
    
    @State
    private var showsBrowser: Bool = false

    var body: some View {
        HStack {
            CopyButton(copyPrefixString() + safe.address!) {
                let prefix = prependingPrefixString()
                SlicedText(string: SlicedString(text: prefix + safe.address!, prefix: prefix.count + 6, suffix: 4))
                    .style(.addressLong)
                    .multilineTextAlignment(.center)
            }

            Button(action: { self.showsBrowser.toggle() }) {
                Image("ico-browse-address")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)
            }
            .frameForTapping()
            .sheet(isPresented: $showsBrowser) {
                SafariViewController(url: self.safe.browserURL)
            }
        }
        // these two lines make sure that the alignment will be by
        // the addreses text's center, and
        .padding([.leading, .trailing], 44)
        // that 'link button' will be visually attached to the trailnig
        .padding(.trailing, -44)
    }

    private func copyPrefixString() -> String {
        AppSettings.copyAddressWithChainPrefix ? prefixString() : ""
    }

    private func prependingPrefixString() -> String {
        AppSettings.prependingChainPrefixToAddresses ? prefixString() : ""
    }

    private func prefixString() -> String {
        safe.chain!.shortName != nil ? "\(safe.chain!.shortName!):" : ""
    }
}
