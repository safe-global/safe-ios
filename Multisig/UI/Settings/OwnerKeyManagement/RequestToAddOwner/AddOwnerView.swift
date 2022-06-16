//
//  AddOwnerView.swift
//  Multisig
//
//  Created by Vitaly on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//


import UIKit

class AddOwnerView: UINibView {

    @IBOutlet weak var ownerInfo: IdenticonInfoView!
    @IBOutlet weak var safeInfo: IdenticonInfoView!

    func set(owner: AddressInfo, badgeName: String? = nil, safe: Safe, reqConfirmations: Int, ownerCount: Int) {
        ownerInfo.set(owner: owner, badgeName: badgeName)
        safeInfo.set(owner: AddressInfo(address: safe.addressValue, name: safe.name!), reqConfirmations: reqConfirmations, ownerCount: ownerCount)
    }
}

