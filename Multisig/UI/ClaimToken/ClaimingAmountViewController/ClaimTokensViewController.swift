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
    private var votingPowerDelegate: Address!

    // Selected safe for which claiming happens.
    private var safe: Safe!

    // Amount for showing in the text field. Nil means empty
    private var displayClaimAmount: UInt256?

    private var formattedClaimAmount: String? {
        guard let amount = displayClaimAmount else { return nil }
        let decimal = BigDecimal(Int256(amount), 18)
        let string = tokenFormatter.string(from: decimal, shortFormat: false)
        return string
    }

    // Amount entered by user.
    private var inputClaimAmount: UInt256?

    // "Max" means whatever amount is available at the point of transaction execution. A special value.
    //      When selected, then display amount will be auto-calculated
    private var isMaxAmountSelected: Bool = false

    // Unix timestamp to base the amount calculations.
    private var timestamp: TimeInterval!

    // Claim data fetched from the data source
    private var claimData: ClaimingAppController.ClaimingData?

    // completion block
    private var onClaim: (() -> Void)?

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
                     tokenDelegate: Address,
                     safe: Safe,
                     onClaim: @escaping () -> ()) {
        self.init(namedClass: Self.superclass())
        self.stepNumber = stepNumber
        self.maxSteps = maxSteps
        self.onClaim = onClaim
        self.votingPowerDelegate = tokenDelegate
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

    private func setInputAmount(_ string: String?) {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty else {
            // empty string
            inputClaimAmount = nil
            return
        }

        guard let decimalInput = tokenFormatter.number(from: string, precision: 18) else {
            // not a number
            inputClaimAmount = nil
            return
        }

        if decimalInput.value == 0 {
            // zero not allowed
            inputClaimAmount = nil
            return
        }

        if decimalInput.value < 0 {
            // negative not allowed
            inputClaimAmount = nil
            return
        }

        guard let claimData = claimData else {
            // claim data not loaded, can't set amount
            inputClaimAmount = nil
            return
        }

        guard let timestamp = timestamp else {
            // internal error, timestamp must be set.
            inputClaimAmount = nil
            return
        }

        // it will truncate the number in case it is too big (> 128 bits).
        let input = Sol.UInt128(big: UInt256(decimalInput.value))

//        if input > claimData.totalAvailableAmount(at: timestamp) {
//            // number too big
//            inputClaimAmount = nil
//            return
//        }

        inputClaimAmount = UInt256(decimalInput.value)
    }

    // claim & delegate
    @objc func didTapClaimButton() {
        // claim button is enabled iff amount is correct and delegate selected
            // amount is correct when amount == MAX OR (amount > 0 && amount <= total available)

        // open the review screen with the selection
            // review screen will create the transaction via controller
    }

    // edit selected delegate
    @IBAction private func editButtonTouched(_ sender: Any) {
        // modal to select delegate or select custom address
        // on completion change the delegate address, selected delegate display
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
// rin:0xEe6f78FeD18A20Af43d394f0F7dDc1aCf5d96d01
    // text field
        // enters valid numbers only
        // has limit on the number of decimals
        // error if negative
        // error if 0
        // error if more than available

        // border is green when field is in focus
        // error is extending vertical size of the field --> the cell must grow


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

                let halfDate = userAllocation.allocation.startDate + 4 * 52 * 7 * 60 * 60 // 4 years, 52 weeks per year
                let vestingStartDate = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(halfDate)))
                cell.headerTooltipText = NSAttributedString(string: "SAFE vesting is vested linearly over 4 years starting on \(vestingStartDate)")

                cell.valueText = formatted(amount: claimData.totalUnvestedAmount(of: claimData.allocationsData, at: timestamp))
                cell.titleTooltipText = NSAttributedString(string: "This includes user allocation of \(userAmount) and Safe guardian allocation of \(ecosystemAmount)")

                // must be set at the end to update values
                cell.style = .lightGuardian
            } else if let userAllocation = userAllocation, claimData.allocationsData.count == 1 {
                let halfDate = userAllocation.allocation.startDate + 4 * 52 * 7 * 60 * 60 // 4 years, 52 weeks per year
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
            cell.text = "Awarded total allocation is 9000.15 SAFE"
            return cell

        case .claimingAmount:
            let cell = tableView.dequeueCell(ClaimedAmountInputCell.self)
//            cell.maxValue = tokenFormatter.string(from: claimingAmount.totalClaimable)
            return cell

        case .selectedDelegate:
            let cell = tableView.dequeueCell(SelectedDelegateCell.self)
//            cell.guardian = guardian
            return cell
        }
    }
}
