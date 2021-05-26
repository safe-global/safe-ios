//
//  OwnerKeyDetailsViewController.swift
//  Multisig
//
//  Created by Moaaz on 5/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OwnerKeyDetailsViewController: UIViewController {
    private var keyInfo: KeyInfo!
    private var exportButton: UIBarButtonItem!
    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressInfoView: AddressInfoView!
    @IBOutlet weak var titleLabel: UILabel!

    convenience init(keyInfo: KeyInfo) {
        self.init()
        self.keyInfo = keyInfo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(keyInfo != nil, "Developer error: expect to have a key")

        navigationItem.title = "Owner Key"

        exportButton = UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(didTapExportButton))
        navigationItem.rightBarButtonItem = exportButton

        nameLabel.setStyle(.headline)

        titleLabel.setStyle(.headline)
        titleLabel.text = "Key address"

        bindData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bindData),
            name: .ownerKeyUpdated,
            object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerKeyDetails)
    }

    @IBAction func removeButtonTouched(_ sender: Any) {
        remove(key: keyInfo)
    }

    @IBAction func editButtonTouched(_ sender: Any) {
        let vc = EditOwnerKeyViewController(keyInfo: keyInfo)
        show(vc, sender: self)
    }

    @objc private func didTapExportButton() {

    }

    @objc private func bindData() {
        nameLabel.text = keyInfo.name
        identiconView.setCircleImage(url: nil, address: keyInfo.address)
        addressInfoView.setAddress(keyInfo.address, showIdenticon: false)
    }

    private func remove(key: KeyInfo) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn’t delete any Safes from this app or from blockchain. Transactions for Safes controlled by this key will no longer be available for signing in this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
            DispatchQueue.main.async {
                PrivateKeyController.remove(keyInfo: key)
                navigationController?.popViewController(animated: true)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}
