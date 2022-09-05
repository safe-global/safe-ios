//
//  ClaimingAmountViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter
import Solidity

class ClaimTokensViewController: LoadableViewController {
    // TODO: nice-to-have: make tooltip a bit narrower so that the text reads better; + dark mode version of tooltip

    // IDs of table rows
    enum RowItem {
        case claimableNow
        case claimableFuture
        case claimableTotal
        case claimingAmount
        case selectedDelegate
    }

    // This screen's position in the claiming screen sequence
    private var stepNumber: Int = 3

    // Maximum number of screens in the sequence
    private var maxSteps: Int = 4

    // Selected delegate address (guardian or a custom address)
    private var delegateAddress: Address?
    private var guardian: Guardian?

    // Selected safe for which claiming happens.
    private var safe: Safe!

    // Unix timestamp to base the amount calculations.
    private var timestamp: TimeInterval!

    // Claim data fetched from the data source
    private var claimData: ClaimingAppController.ClaimingData?

    var completion: () -> Void = { }
    var onEditDelegate: () -> Void = { }

    private var stepLabel: UILabel!
    private var claimButtonContainer: UIView!
    private var claimButton: UIButton!
    private var claimButtonBottom: NSLayoutConstraint!
    private var keyboardBehavior: KeyboardAvoidingBehavior!
    private var controller: ClaimingAppController!

    private var rows: [RowItem] = [.claimableNow, .claimableFuture, .claimableTotal, .claimingAmount, .selectedDelegate]

    private let tokenFormatter = TokenFormatter()

    convenience init(stepNumber: Int = 3,
                     maxSteps: Int = 4,
                     tokenDelegate: Address?,
                     guardian: Guardian?,
                     safe: Safe) {
        self.init(namedClass: Self.superclass())
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.delegateAddress = tokenDelegate
        self.guardian = guardian
        self.safe = safe

        // TODO: inject from outside
        controller = ClaimingAppController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Your SAFE allocation"

        view.backgroundColor = .backgroundSecondary

        tableView.registerCell(ClaimedAmountInputCell.self)
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

        ViewControllerFactory.removeNavigationBarBorder(self)

        addClaimButton()

        claimButton.isEnabled = false

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: tableView)
        keyboardBehavior.adjustsInsets = false

        keyboardBehavior.willShowKeyboard = { [unowned self] kbFrame in
            UIView.animate(withDuration: 0.25) { [unowned self] in
                claimButtonBottom.constant = kbFrame.height - view.safeAreaInsets.bottom
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }

        keyboardBehavior.willHideKeyboard = { [unowned self] in
            UIView.animate(withDuration: 0.25) { [unowned self] in
                claimButtonBottom.constant = 0
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }

        notificationCenter.addObserver(self, selector: #selector(didBeginEditing), name: UITextField.textDidBeginEditingNotification, object: nil)
    }

    fileprivate func addClaimButton() {
        claimButton = UIButton(type: .custom)
        claimButton.setText("Claim & Delegate", .filled)
        claimButton.translatesAutoresizingMaskIntoConstraints = false
        claimButton.addTarget(self, action: #selector(didTapClaimButton), for: .touchUpInside)

        claimButtonContainer = UIView()
        claimButtonContainer.backgroundColor = .backgroundSecondary
        claimButtonContainer.translatesAutoresizingMaskIntoConstraints = false

        claimButtonContainer.addSubview(claimButton)
        view.addSubview(claimButtonContainer)

        claimButtonContainer.addConstraints([
            claimButton.leadingAnchor.constraint(equalTo: claimButtonContainer.leadingAnchor, constant: 16),
            claimButtonContainer.trailingAnchor.constraint(equalTo: claimButton.trailingAnchor, constant: 16),
            claimButton.topAnchor.constraint(equalTo: claimButtonContainer.topAnchor, constant: 8),
            claimButtonContainer.bottomAnchor.constraint(equalTo: claimButton.bottomAnchor, constant: 20),
            claimButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // need to remember in order to modify bottom spacing when keyboard is shown or hidden
        claimButtonBottom = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: claimButtonContainer.bottomAnchor)

        // inject the button container below tableView and above the bottom of the screen

            // reset table view layout
        let tableViewConstraints = view.constraints.filter { ($0.firstItem as? UITableView) == tableView }
        NSLayoutConstraint.deactivate(tableViewConstraints)

        view.addConstraints([
            // re-attach table view
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: claimButtonContainer.topAnchor),

            // attach button container
            claimButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            claimButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            claimButtonBottom
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc func didBeginEditing(_ notification: NSNotification) {
        guard let textField = notification.object as? UITextField else { return }
        keyboardBehavior.activeTextField = textField
    }

    // claim & delegate
    @objc func didTapClaimButton() {
        guard
            let _ = inputAmount,
            let _ = claimData,
            let _ = safe,
            let _ = delegateAddress,
            let _ = timestamp
        else {
            return
        }

        completion()
    }

    var isMax: Bool {
        guard
            let row = rows.firstIndex(of: .claimingAmount),
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ClaimedAmountInputCell
        else {
            return false
        }
        return cell.isMax
    }

    var inputAmount: Sol.UInt128? {
        guard
            let row = rows.firstIndex(of: .claimingAmount),
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ClaimedAmountInputCell
        else {
            return nil
        }
        return cell.value
    }

    // edit selected delegate
    @IBAction private func editButtonTouched(_ sender: Any) {
        onEditDelegate()
    }

    // pull-to-refresh, initial reload
    override func reloadData() {
        super.reloadData()

        timestamp = Date().timeIntervalSince1970

        keyboardBehavior.hideKeyboard()

        controller.asyncFetchData(account: safe.addressValue) { [weak self] result in
            guard let self = self else { return }
            do {
                self.claimData = try result.get()
                self.onSuccess()
            } catch {
                self.onError(GSError.error(description: "Failed to load data", error: error))
            }
        }
    }

}

extension ClaimTokensViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func formatted(amount: Sol.UInt128) -> String {
        let decimal = BigDecimal(Int256(amount.big()), 18)
        // FIXME: this won't produce 2 decimals!
        // this also cuts off, i.e. it doesn't round up
        let value = tokenFormatter.string(from: decimal)
        let amount = value + " SAFE"
        return amount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .claimableNow:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim now"
            cell.titleText = "Total"
            cell.tooltipHostView = view

            guard let claimData = claimData else {
                // defaults when data not loaded
                cell.valueText = "..."
                cell.titleTooltipText = nil
                cell.headerTooltipText = nil

                // must be set at the end to update values
                cell.style = .darkUser
                return cell
            }


            let userAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("user")
            }
            let ecosystemAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("ecosystem")
            }

            if let userAllocation = userAllocation, let ecosystemAllocation = ecosystemAllocation, claimData.allocationsData.count == 2 {

                let userAmount = formatted(amount: claimData.availableAmount(for: userAllocation, at: timestamp))
                let ecosystemAmount = formatted(amount: claimData.availableAmount(for: ecosystemAllocation, at: timestamp))

                cell.valueText = formatted(amount: claimData.totalAvailableAmount(of: claimData.allocationsData, at: timestamp))
                cell.headerTooltipText = nil
                cell.titleTooltipText = NSAttributedString(string: "This includes user allocation of \(userAmount) and Safe guardian allocation of \(ecosystemAmount)")

                // must be set at the end to update values
                cell.style = .darkGuardian
            } else if userAllocation != nil, claimData.allocationsData.count == 1 {
                cell.valueText = formatted(amount: claimData.totalAvailableAmount(of: claimData.allocationsData, at: timestamp))
                cell.headerTooltipText = nil
                cell.titleTooltipText = NSAttributedString(string: "Not eligible for Safe Guardian allocation. Contribute to the community to become a Safe Guardian.")

                // must be set at the end to update values
                cell.style = .darkUser
            } else {
                assertionFailure("Data misconfiguration: user or ecosystem allocations not found")
                cell.valueText = "n/a"
                cell.headerTooltipText = nil
                cell.titleTooltipText = nil

                // must be set at the end to update values
                cell.style = .darkUser
            }
            return cell

        case .claimableFuture:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim in the future (vesting)"
            cell.titleText = "Total"
            cell.tooltipHostView = view

            guard let claimData = claimData else {
                // defaults when data not loaded
                cell.valueText = "..."
                cell.titleTooltipText = nil
                cell.headerTooltipText = nil

                // must be set at the end to update values
                cell.style = .lightUser
                return cell
            }

            let userAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("user")
            }
            let ecosystemAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("ecosystem")
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short


            if let userAllocation = userAllocation, let ecosystemAllocation = ecosystemAllocation, claimData.allocationsData.count == 2 {

                let userAmount = formatted(amount: claimData.unvestedAmount(for: userAllocation, at: timestamp))
                let ecosystemAmount = formatted(amount: claimData.unvestedAmount(for: ecosystemAllocation, at: timestamp))

                let halfDate = userAllocation.allocation.startDate + 4 * 52 * 7 * 24 * 60 * 60 // 4 years, 52 weeks per year
                let vestingStartDate = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(halfDate)))
                cell.headerTooltipText = NSAttributedString(string: "SAFE vesting is vested linearly over 4 years starting on \(vestingStartDate)")

                cell.valueText = formatted(amount: claimData.totalUnvestedAmount(of: claimData.allocationsData, at: timestamp))
                cell.titleTooltipText = NSAttributedString(string: "This includes user allocation of \(userAmount) and Safe guardian allocation of \(ecosystemAmount)")

                // must be set at the end to update values
                cell.style = .lightGuardian
            } else if let userAllocation = userAllocation, claimData.allocationsData.count == 1 {
                let halfDate = userAllocation.allocation.startDate + 4 * 52 * 7 * 24 * 60 * 60 // 4 years, 52 weeks per year
                let vestingStartDate = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(halfDate)))
                cell.headerTooltipText = NSAttributedString(string: "SAFE vesting is vested linearly over 4 years starting on \(vestingStartDate)")

                cell.valueText = formatted(amount: claimData.totalUnvestedAmount(of: claimData.allocationsData, at: timestamp))
                cell.titleTooltipText = NSAttributedString(string: "Not eligible for Safe Guardian allocation. Contribute to the community to become a Safe Guardian.")

                // must be set at the end to update values
                cell.style = .lightUser
            } else {
                assertionFailure("Data misconfiguration: user or ecosystem allocations not found")
                cell.valueText = "n/a"
                cell.headerTooltipText = nil
                cell.titleTooltipText = nil

                // must be set at the end to update values
                cell.style = .darkUser
            }

            return cell

        case .claimableTotal:
            let cell = tableView.dequeueCell(AllocationTotalCell.self)


            guard let claimData = claimData else {
                // defaults when data not loaded
                cell.text = "Awarded total allocation ..."
                return cell
            }


            let userAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("user")
            }
            let ecosystemAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("ecosystem")
            }

            if userAllocation != nil, ecosystemAllocation != nil, claimData.allocationsData.count == 2 {

                let amount = formatted(amount: claimData.totalAllocatedAmount(of: claimData.allocationsData, at: timestamp))
                cell.text = "Awarded total allocation is \(amount)"

            } else if userAllocation != nil, claimData.allocationsData.count == 1 {

                let amount = formatted(amount: claimData.totalAllocatedAmount(of: claimData.allocationsData, at: timestamp))
                cell.text = "Awarded total allocation is \(amount)"

            } else {
                assertionFailure("Data misconfiguration: user or ecosystem allocations not found")
                cell.text = "Awarded total allocation is n/a"
            }

            return cell

        case .claimingAmount:
            let cell = tableView.dequeueCell(ClaimedAmountInputCell.self)

            guard let claimData = claimData else {
                // defaults when data not loaded
                cell.valueRange = (0..<0)
                return cell
            }

            let userAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("user")
            }
            let ecosystemAllocation = claimData.allocationsData.first {
                $0.allocation.tag.contains("ecosystem")
            }

            if userAllocation != nil, ecosystemAllocation != nil, claimData.allocationsData.count == 2 {

                let totalAmount = claimData.totalAvailableAmount(of: claimData.allocationsData, at: timestamp)
                assert(totalAmount >= 1, "Total amount is less than 1")
                cell.valueRange = totalAmount >= 1 ? (1..<totalAmount) : (0..<0)

            } else if userAllocation != nil, claimData.allocationsData.count == 1 {

                let totalAmount = claimData.totalAvailableAmount(of: claimData.allocationsData, at: timestamp)
                assert(totalAmount >= 1, "Total amount is less than 1")
                cell.valueRange = totalAmount >= 1 ? (1..<totalAmount) : (0..<0)

            } else {
                assertionFailure("Data misconfiguration: user or ecosystem allocations not found")
                cell.valueRange = (0..<0)
            }

            cell.didEndValidating = { [unowned tableView, unowned self] error in
                tableView.beginUpdates()
                tableView.endUpdates()
                claimButton.isEnabled = (error == nil)
            }

            return cell

        case .selectedDelegate:
            let cell = tableView.dequeueCell(SelectedDelegateCell.self)

            if let address = delegateAddress {
                cell.set(address: address, chain: controller.chain)
            } else {
                cell.guardian = guardian
            }

            return cell
        }
    }
}
