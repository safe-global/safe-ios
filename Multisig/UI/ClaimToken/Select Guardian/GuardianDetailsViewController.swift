//
//  GuardianDetailsViewController.swift
//  Multisig
//
//  Created by Vitaly on 27.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class GuardianDetailsViewController: UIViewController {

    @IBOutlet weak var identiconInfoView: IdenticonInfoView!
    @IBOutlet weak var viewOnEtherscan: HyperlinkButtonView!
    @IBOutlet weak var reasonTitleLabel: UILabel!
    @IBOutlet weak var reasonTextLabel: UILabel!
    @IBOutlet weak var contributionTitleLabel: UILabel!
    @IBOutlet weak var contributionTextLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!

    private var stepLabel: UILabel!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 4

    var chain: Chain! = Chain.mainnetChain()
    var guardian: Guardian!
    var onSelected: ((Guardian) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.makeTransparentNavigationBar(self)
        navigationItem.hidesBackButton = false
        title = "Choose a delegate"

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        identiconInfoView.setGuardian(guardian: guardian)

        viewOnEtherscan.setText("View on Etherscan")

        reasonTitleLabel.setStyle(.headline)
        reasonTextLabel.setStyle(.secondary)
        reasonTextLabel.text = guardian.reason

        contributionTitleLabel.setStyle(.headline)
        contributionTextLabel.setStyle(.secondary)
        contributionTextLabel.text = guardian.previousContribution

        continueButton.setText("Select & Continue", .filled)

        if guardian.address == Address.zero {

            continueButton.isEnabled = false

            DispatchQueue.main.async { [unowned self] in
                if let ensName = guardian.ensName {
                    let blockchainDomainManager = BlockchainDomainManager(
                        rpcURL: chain.authenticatedRpcUrl,
                        chainId: chain.id!,
                        ensRegistryAddress: AddressString(chain.ensRegistryAddress!)
                    )
                    do {

                        let guardianAddress = try blockchainDomainManager.resolveEnsDomain(domain: ensName)

                        viewOnEtherscan.url = chain.browserURL(address: guardianAddress.checksummed)

                        guardian = Guardian(
                            name: guardian.name,
                            reason: guardian.reason,
                            previousContribution: guardian.previousContribution,
                            address: guardianAddress,
                            ensName: guardian.ensName,
                            imageURLString: guardian.imageURLString
                        )

                        continueButton.isEnabled = true

                    } catch {
                        let gsError = GSError.error(description: "ENS resolution failed", error: error)
                        App.shared.snackbar.show(error: gsError)
                    }
                } else {
                    App.shared.snackbar.show(message: "Missing ENS name and address")
                }
            }

        } else {
            viewOnEtherscan.url = chain.browserURL(address: guardian.address.checksummed)
        }
    }

    @IBAction func didTapContinueButton(_ sender: Any) {
        onSelected?(guardian)
    }
}
