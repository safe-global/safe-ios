//
//  ContractVersionCell.swift
//  Multisig
//
//  Created by Moaaz on 5/7/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ContractVersionCell: View {

    private let masterCopy: Address
    private let versionStatus: GnosisSafe.VersionStatus
    private let iconSize: CGFloat = 36
    private let lineSpacing: CGFloat = 12
    private let statusIconSize: CGFloat = 14

    init(masterCopy: String?) {
        self.masterCopy = masterCopy.flatMap { Address($0) } ?? .zero
        versionStatus = App.shared.gnosisSafe.version(masterCopy: self.masterCopy)
    }

    var address: String {
        masterCopy.checksummed
    }

    var versionView: Text {
        switch versionStatus {
        case .unknown:
            return Text("Unknown")
        case .upToDate(let v), .upgradeAvailable(let v):
            return Text(v)
        }
    }

    var upgradeStatusView: some View {
        switch versionStatus {
        case .unknown:
            return AnyView(EmptyView())
        case .upToDate:
            return AnyView(
                HStack {
                    Image.checkmark(size: statusIconSize)
                    Text("Up to date")
                        .body(.gnoHold)
                }
            )
        case .upgradeAvailable:
            return AnyView(
                HStack {
                    Image.exclamation(size: statusIconSize)
                    Text("Upgrade available")
                        .body(.gnoTomato)
                }
            )
        }
    }

    var body: some View {
        HStack(spacing: lineSpacing) {
            AddressImage(address)
                .frame(width: iconSize, height: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    versionView
                        .headline()
                    upgradeStatusView
                }
                SlicedText(address)
                    .style(.addressShortLight)
            }
            
            Spacer()
            
            BrowseAddressView(address: address)
        }
    }
}

struct ContractVersionCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ContractVersionCell(masterCopy: "0xb6029EA3B2c51D09a50B53CA8012FeEB05bDa35A")
            ContractVersionCell(masterCopy: "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F")
        }
    }
}
