//
//  SafeInfoView.swift
//  Multisig
//
//  Created by Moaaz on 4/23/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// Info view split into two objects so that the content view would track
// changes to the safe, but the parent view tracks changes to the selection.
struct SafeInfoView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    var body: some View {
        ZStack {
            if selectedSafe.first == nil {
                Text("No Safe is selected").body()
            } else {
                SafeInfoContentView(safe: selectedSafe.first!, appendPrefix: AppSettings.prependingChainPrefixToAddresses)
            }
        }
        .background(Color.backgroundSecondary)
    }
}

struct SafeInfoContentView: View {
    @ObservedObject var safe: Safe
    @State var appendPrefix: Bool = true
    var body: some View {
        VStack (alignment: .center) {
            AddressImage(safe.address).frame(width: 56, height: 56)
            Text(safe.displayName).headline().padding(.top, 6)

            if let name = safe.chain?.name,
               let backgroundColor = safe.chain?.backgroundColor.map(Color.init) {
                SwiftUINetworkIndicator(text: name, color: backgroundColor)
                    .padding(.top, 6)
            }

            if safe.hasAddress {
                CenteredAddressWithLink(safe: safe).padding(.top, 3)
            }

            LoadableENSNameText(safe: safe, showsLoading: false)

            QRView(value: prefixString() + safe.address!)
                .padding(.top, 12)

            if (AppSettings.prependingChainPrefixToAddresses) {
                EmptyView().background(Color.icon)
                Toggle(isOn: $appendPrefix, label: {
                    Text("QR code with chain prefix").fixedSize().font(.headline)
                }).padding(.top, 20).toggleStyle(SwitchToggleStyle(tint: Color.success))
            }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            Tracker.trackEvent(.safeReceive)
        }
    }

    private func prefixString() -> String {
        (appendPrefix && safe.chain!.shortName != nil ? "\(safe.chain!.shortName!):" : "" )
    }
}

struct SwiftUINetworkIndicator: View {
    var text: String
    var color: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "circle.fill").resizable().frame(width: 12, height: 12).foregroundColor(color)

            Text(text).font(.subheadline).foregroundColor(.labelPrimary)
        }
        // shift left to compensate for the dot and spacing so that the text would be centered in the container
        .padding(.leading, -(9 + 12))
    }
}

struct SafeInfoContentView_Previews: PreviewProvider {
    static var previews: some View {
        SafeInfoContentView(safe: Safe())
        .padding()
    }
}
