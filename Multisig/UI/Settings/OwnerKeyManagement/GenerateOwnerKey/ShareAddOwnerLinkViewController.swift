//
//  ShareAddOwnerLinkViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/12/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ShareAddOwnerLinkViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet private weak var shareLinkView: ShareTextView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var addOwnerView: AddOwnerView!

    var owner: Address!
    var safe: Safe!
    var onFinish: (() -> ())!

    var steps: [Step] = []

    convenience init(owner: Address, safe: Safe, onFinish: @escaping () -> ()) {
        self.init(namedClass: ShareAddOwnerLinkViewController.self)
        self.owner = owner
        self.safe = safe
        self.onFinish = onFinish
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)
        assert(owner != nil)

        titleLabel.setStyle(.title2)
        doneButton.setText("Done", .filled)

        tableView.registerCell(StepInstructionTableViewCell.self)

        steps = [Step(number: "1", text: "Use the link below and send it to the owners."),
                 Step(number: "2", text: "Follow the instructions and create an ‘Add or replace owner’ transaction."),
                 Step(number: "3", text: "Once the transaction is executed, the key will become a Safe owner.")]

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        let params = AddOwnerRequestParameters(chain: safe.chain!, safeAddress: safe.addressValue, ownerAddress: owner)
        let text = params.link()

        shareLinkView.set(text: text)
        shareLinkView.onShare = { [weak self] text in
            let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            vc.completionWithItemsHandler = { _, success, _, _ in
                if success {
                    App.shared.snackbar.show(message: "Add owner link shared")
                }
            }

            self?.present(vc, animated: true, completion: nil)
        }

        if let ownerKeyInfo = try? KeyInfo.firstKey(address: owner) {
            addOwnerView.set(owner: AddressInfo(address: ownerKeyInfo.address,
                                                name: ownerKeyInfo.name),
                             badgeName: ownerKeyInfo.keyType.badgeName,
                             safe: safe,
                             reqConfirmations: Int(safe.threshold!),
                             ownerCount: safe.ownersInfo?.count ?? 0)

        } else {
            let (ownerName, _) = NamingPolicy.name(for: owner,
                                                    info: nil,
                                                    chainId: safe.chain!.id!)
            addOwnerView.set(owner: AddressInfo(address: owner,
                                                name: ownerName),
                             safe: safe,
                             reqConfirmations: Int(safe.threshold!),
                             ownerCount: safe.ownersInfo?.count ?? 0)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenAddOwnerShareLink)
    }

    @IBAction func doneButtonTouched(_ sender: Any) {
        onFinish()
    }

    struct Step {
        let number: String
        let text: String
    }
}

extension ShareAddOwnerLinkViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentStep = steps[indexPath.row]
        let cell = tableView.dequeueCell(StepInstructionTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.separatorInset.left = .greatestFiniteMagnitude
        cell.circleLabel.text = currentStep.number
        cell.headerLabel.isHidden = true
        cell.verticalBarView.isHidden = indexPath.row == steps.count - 1
        cell.descriptionLabel.text = currentStep.text
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        steps.count
    }
}
