//
//  ChooseOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/10/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseOwnerKeyViewController: UIViewController {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!

    private var owners: [KeyInfo] = []
    private var descriptionText: String!
    var completionHandler: ((KeyInfo?) -> Void)?

    convenience init(owners: [KeyInfo], descriptionText: String, completionHandler: ((KeyInfo?) -> Void)? = nil) {
        self.init()
        self.owners = owners
        self.descriptionText = descriptionText
        self.completionHandler = completionHandler
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.chooseOwner)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select owner key"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(didTapCloseButton))
        
        tableView.registerCell(ChooseOwnerTableViewCell.self)
        descriptionLabel.text = descriptionText
        descriptionLabel.setStyle(.primary)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}

extension ChooseOwnerKeyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        owners.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ChooseOwnerTableViewCell.self)
        let keyInfo = owners[indexPath.row]

        cell.set(address: keyInfo.address, title: keyInfo.displayName)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if App.shared.auth.isPasscodeSet && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            let vc = EnterPasscodeViewController()
            vc.completion = { [weak self] success in
                guard let `self` = self else { return }
                self.completionHandler?(success ? self.owners[indexPath.row] : nil)
                self.dismiss(animated: true, completion: nil)
            }
           show(vc, sender: self)
        } else {
            completionHandler?(owners[indexPath.row])
        }
    }
}
