//
//  ClaimingAmountViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class ClaimingAmountViewController: LoadableViewController {
    // TODO: tap on the background -> close keyboard
    // TODO: tap on the background -> close all tooltips
    // TODO: keyboard open/close -> scroll to show text field, delegate, and the button
    // TODO: standard, collapsible title of navigation
    // TODO: nice-to-have: make tooltip a bit narrower so that the text reads better; + dark mode version of tooltip

    enum RowItem {
        case claimableNow
        case claimableFuture
        case claimableTotal
        case claimingAmount
        case selectedDelegate
    }

    private var guardian: Guardian!
    private var safe: Safe!
    private var stepNumber: Int = 3
    private var maxSteps: Int = 4
    private var onClaim: ((Guardian, String) -> ())?
    private var claimingAmount: SafeClaimingAmount!

    private weak var claimButtonContainer: UIView!
    private weak var claimButton: UIButton!

    private var stepLabel: UILabel!

    var rows: [RowItem] = [.claimableNow, .claimableFuture, .claimableTotal, .claimingAmount, .selectedDelegate]
    private let tokenFormatter = TokenFormatter()

    convenience init(stepNumber: Int = 3,
                     maxSteps: Int = 4,
                     guardian: Guardian,
                     safe: Safe,
                     onClaim: @escaping (Guardian, String) -> ()) {
        self.init(namedClass: Self.superclass())
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onClaim = onClaim
        self.guardian = guardian
        self.safe = safe
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        claimingAmount = SafeClaimingController.shared.claimingAmountFor(safe: safe.addressValue)
        assert(claimingAmount != nil)

        view.backgroundColor = .backgroundSecondary

        tableView.registerCell(EnterClaimingAmountTableViewCell.self)
        tableView.registerCell(AllocationTotalCell.self)
        tableView.registerCell(AllocationBoxCell.self)
        tableView.registerCell(SelectedDelegateCell.self)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        navigationItem.title = "Your SAFE allocation"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        ViewControllerFactory.removeNavigationBarBorder(self)

        addClaimButton()
    }

    fileprivate func addClaimButton() {
        let button = UIButton(type: .custom)
        button.setText("Claim & Delegate", .filled)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapClaimButton), for: .touchUpInside)
        claimButton = button

        let container = UIView()
        container.backgroundColor = .backgroundSecondary
        container.translatesAutoresizingMaskIntoConstraints = false
        claimButtonContainer = container

        container.addSubview(button)
        view.addSubview(container)

        container.addConstraints([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            button.heightAnchor.constraint(equalToConstant: 56)
        ])

        view.addConstraints([
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        var insets = tableView.contentInset
        insets.bottom = 16
        tableView.contentInset = insets
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }

    @objc func didTapClaimButton() {
    }

    @IBAction private func editButtonTouched(_ sender: Any) {
    }

    override func reloadData() {
    }
}

extension ClaimingAmountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .claimableNow:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim now"
            cell.titleText = "Total"
            cell.valueText = "3,000.05 SAFE"
            cell.titleTooltipText = NSAttributedString(string: "This includes 1000 SAFE for user allocation and 2000.05 SAFE for guardian allocation.")
            cell.tooltipHostView = view
            // must be set at last
            cell.style = .darkGuardian
            return cell

        case .claimableFuture:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim in the future (vesting)"
            cell.titleText = "Total"
            cell.valueText = "6,000.10 SAFE"
            cell.headerTooltipText = NSAttributedString(string: "SAFE vesting is vested linearly over 4 years starting on 01.10.2022, 14:30:00 (Europe/Berlin).")
            cell.titleTooltipText = NSAttributedString(string: "This includes a Safe guardian allocation of 2000 SAFE.")
            cell.tooltipHostView = view
            cell.style = .lightGuardian
            return cell

        case .claimableTotal:
            let cell = tableView.dequeueCell(AllocationTotalCell.self)
            cell.text = "Awarded total allocation is 9000.15 SAFE"
            return cell

        case .claimingAmount:
            let cell = tableView.dequeueCell(EnterClaimingAmountTableViewCell.self)
            cell.set(value: "0",
                     maxValue: tokenFormatter.string(from: claimingAmount.totalClaimable))
            return cell

        case .selectedDelegate:
            let cell = tableView.dequeueCell(SelectedDelegateCell.self)
            cell.guardian = guardian
            return cell
        }
    }
}
