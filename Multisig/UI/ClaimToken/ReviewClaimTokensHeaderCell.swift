//
//  ReviewClaimTokensHeaderCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ReviewClaimTokensHeaderCell: UITableViewCell {
    @IBOutlet private weak var amountView: TokenInfoView!
    @IBOutlet private weak var delegateView: AddressInfoView!
    @IBOutlet private weak var fromView: AddressInfoView!
    @IBOutlet private weak var toView: AddressInfoView!

    var showsDelegate: Bool = true {
        didSet {
            delegateView.isHidden = !showsDelegate
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        amountView.setTitle("You're claiming:", style: .body)
        delegateView.setTitle("Delegating voting power to:", style: .body)
        fromView.setTitle("From:", style: .body)
        toView.setTitle("Interact with:", style: .body)
    }

    func setAmount(text: String, image: UIImage?) {
        amountView.setImage(image)
        amountView.setText(text, style: .headline)
    }

    func setDelegate(guardian: Guardian?, address: Address?, chain: Chain) {
        if let address = address {
            set(address: address, chain: chain, in: delegateView)
        } else if let guardian = guardian {
            delegateView.setAddress(
                guardian.address.address,
                ensName: guardian.ens,
                label: guardian.name,
                imageUri: guardian.imageURL,
                browseURL: chain.browserURL(address: guardian.address.description),
                prefix: chain.shortName
            )
        } else {
            assertionFailure("Missing a value")
        }
    }

    func setFrom(address: Address, chain: Chain) {
        set(address: address, chain: chain, in: fromView)
    }

    func setTo(address: Address, chain: Chain) {
        set(address: address, chain: chain, in: toView)
    }

    func setTo(info: SCGModels.AddressInfo, chain: Chain) {
        set(info: info, chain: chain, in: toView)
    }

    private func set(info: SCGModels.AddressInfo, chain: Chain, in view: AddressInfoView) {
        let (name, image) = NamingPolicy.name(for: info, chainId: chain.id!)
        view.setAddress(
            info.value.address,
            label: name, imageUri: image,
            browseURL: chain.browserURL(address: info.value.description),
            prefix: chain.shortName)
    }

    private func set(address: Address, chain: Chain, in view: AddressInfoView) {
        let (name, image) = NamingPolicy.name(for: address, chainId: chain.id!)
        view.setAddress(
            address,
            label: name,
            imageUri: image,
            browseURL: chain.browserURL(address: address.checksummed),
            prefix: chain.shortName)
    }
}
