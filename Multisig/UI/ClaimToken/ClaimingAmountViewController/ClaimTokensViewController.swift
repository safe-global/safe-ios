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
    // IDs of table rows
    enum RowItem {
        case claimableNow
        case claimableFuture
        case claimableTotal
        case claimingAmount
        case selectedDelegate
    }

    // Selected delegate address (guardian or a custom address)
    private (set) var delegateAddress: Address?
    private (set) var guardian: Guardian?

    // Selected safe for which claiming happens.
    private var safe: Safe!

    // Unix timestamp to base the amount calculations.
    private (set) var timestamp: TimeInterval!

    // Claim data fetched from the data source
    private (set) var claimData: ClaimingAppController.ClaimingData?

    // whether user used max button
    var hasSelectedMaxAmount: Bool = false

    // amount entered by user
    var inputAmount: Sol.UInt128? = nil

    var completion: () -> Void = { }
    var onEditDelegate: () -> Void = { }

    private var claimButtonContainer: UIView!
    private var claimButton: UIButton!
    private var claimButtonBottom: NSLayoutConstraint!
    private var keyboardBehavior: KeyboardAvoidingBehavior!
    private var controller: ClaimingAppController!

    private var rows: [RowItem] = [.claimableNow, .claimableFuture, .claimableTotal, .claimingAmount, .selectedDelegate]

    private let tokenFormatter = TokenFormatter()

    convenience init(tokenDelegate: Address?,
                     guardian: Guardian?,
                     safe: Safe,
                     controller: ClaimingAppController) {
        self.init(namedClass: Self.superclass())
        self.delegateAddress = tokenDelegate
        self.guardian = guardian
        self.safe = safe
        self.controller = controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimForm)

        title = "Your allocation"
        navigationItem.largeTitleDisplayMode = .always

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

        ViewControllerFactory.removeNavigationBarBorder(self)

        addClaimButton()

        claimButton.isEnabled = false

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: tableView)
        keyboardBehavior.adjustsInsets = false

        keyboardBehavior.willShowKeyboard = { [unowned self] kbFrame, duration in
            UIView.animate(withDuration: duration) { [unowned self] in
                claimButtonBottom.constant = kbFrame.height - view.safeAreaInsets.bottom
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }

        keyboardBehavior.willHideKeyboard = { [unowned self] duration in
            UIView.animate(withDuration: duration) { [unowned self] in
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

    @objc func didTapClaimButton() {
        Tracker.trackEvent(.userClaimFormClaim)
        guard
            safe != nil,
            timestamp != nil,
            claimButtonEnabled
        else {
            return
        }

        completion()
    }

    // edit selected delegate
    @IBAction private func editButtonTouched(_ sender: Any) {
        Tracker.trackEvent(.userClaimFormDel)
        onEditDelegate()
    }

    override func didStartRefreshing() {
        super.didStartRefreshing()
        Tracker.trackEvent(.userClaimFormReload)
    }

    // pull-to-refresh, initial reload
    override func reloadData() {
        super.reloadData()

        timestamp = lastBlockTimestampEstimation()
        keyboardBehavior.hideKeyboard()

        claimButton.isEnabled = false

        controller.asyncFetchData(account: safe.addressValue) { [weak self] result in
            guard let self = self else { return }
            defer {
                self.claimButton.isEnabled = self.claimButtonEnabled
            }
            do {
                let data = try result.get()

                if let error = data.findError() {
                    self.onError(GSError.error(description: "Internal data error: \(error)"))
                    return
                }

                self.claimData = data
                self.onSuccess()
            } catch {
                self.onError(GSError.error(description: "Failed to load data", error: error))
            }
        }
    }

    var claimButtonEnabled: Bool {
        guard let claimData = claimData else {
            return false
        }

        let values = displayValues(from: claimData)
        let isAmountWithinRange = inputAmount != nil && values.availableRange.contains(inputAmount!) && inputAmount != 0
        let isAmountCorrect = hasSelectedMaxAmount || isAmountWithinRange

        let isDelegateCorrect = delegateAddress != nil || guardian != nil

        return isAmountCorrect && isDelegateCorrect
    }

    private func lastBlockTimestampEstimation() -> TimeInterval {
        // This to make sure that the last block time interval is less than the used one
        Date().timeIntervalSince1970 - 30
    }
}

extension ClaimTokensViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        if let claimData = claimData {
            return claimableUserAndEcosystemCell(for: row, claimData: claimData)
        } else {
            return claimDataUnavailableCells(for: row)
        }
    }

    func formatted(amount: Sol.UInt128) -> String {
        let decimal = BigDecimal(Int256(amount.big()), 18)
        let value = tokenFormatter.string(from: decimal)
        let amount = value + " SAFE"
        return amount
    }

    func claimDataUnavailableCells(for row: RowItem) -> UITableViewCell {
        switch row {
        case .claimableNow:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim now"
            cell.titleText = "Total"
            cell.tooltipHostView = view
            cell.valueText = "..."
            cell.titleTooltipText = nil
            cell.headerTooltipText = nil

            // must be set at the end to update values
            cell.style = .darkUser
            return cell
        case .claimableFuture:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim in the future (vesting)"
            cell.titleText = "Total"
            cell.tooltipHostView = view

            cell.valueText = "..."
            cell.titleTooltipText = nil
            cell.headerTooltipText = nil

            // must be set at the end to update values
            cell.style = .lightUser
            return cell
        case .claimableTotal:
            let cell = tableView.dequeueCell(AllocationTotalCell.self)
            cell.text = "Awarded total allocation ..."
            return cell
        case .claimingAmount:
            let cell = tableView.dequeueCell(ClaimedAmountInputCell.self)
            cell.valueRange = (0..<0)
            return cell
        case .selectedDelegate:
            return delegateCell()
        }
    }

    func delegateCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(SelectedDelegateCell.self)

        if let address = delegateAddress {
            cell.set(address: address, chain: controller.chain)
        } else {
            cell.guardian = guardian
        }

        return cell
    }

    func claimableUserAndEcosystemCell(for row: RowItem, claimData: ClaimingAppController.ClaimingData) -> UITableViewCell {

        let data = displayValues(from: claimData)

        switch row {
        case .claimableNow:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim now"
            cell.titleText = "Total"
            cell.tooltipHostView = view

            cell.valueText = data.vestedValue
            cell.headerTooltipText = nil
            cell.titleTooltipText = data.vestedAmountTooltip
            // must be set at the end to update values
            cell.style = data.vestedStyle
            return cell

        case .claimableFuture:
            let cell = tableView.dequeueCell(AllocationBoxCell.self)
            cell.headerText = "Claim in the future (vesting)"
            cell.titleText = "Total"
            cell.tooltipHostView = view

            cell.headerTooltipText = data.unvestedDurationTooltip
            cell.tapAllocationHeaderButtonTrackingEvent = .userClaimFormFutTp
            cell.valueText = data.unvestedValue
            cell.titleTooltipText = data.unvestedAmountTooltip
            // must be set at the end to update values
            cell.style = data.unvestedStyle
            return cell

        case .claimableTotal:
            let cell = tableView.dequeueCell(AllocationTotalCell.self)
            cell.text = data.totalValue
            return cell

        case .claimingAmount:
            let cell = tableView.dequeueCell(ClaimedAmountInputCell.self)
            cell.valueRange = data.availableRange
            cell.didEndValidating = { [unowned self, unowned cell] error in
                tableView.beginUpdates()
                tableView.endUpdates()
                hasSelectedMaxAmount = cell.isMax
                inputAmount = cell.value
                claimButton.isEnabled = (error == nil) && claimButtonEnabled
            }
            cell.set(redeemDeadlineLabelVisible: !data.isRedeemed)
            return cell

        case .selectedDelegate:
            return delegateCell()
        }
    }

    struct DisplayValues {
        var vestedValue: String
        var vestedAmountTooltip: NSAttributedString?
        var vestedStyle: AllocationBoxCell.Style

        var unvestedDurationTooltip: NSAttributedString?
        var unvestedValue: String
        var unvestedAmountTooltip: NSAttributedString?
        var unvestedStyle: AllocationBoxCell.Style

        var totalValue: String
        var availableRange: Range<Sol.UInt128>

        var isRedeemed: Bool
    }

    func displayValues(from claimData: ClaimingAppController.ClaimingData) -> DisplayValues {
        let userAllocation = claimData.allocationsData.first {
            $0.allocation.tag.contains("user")
        }
        let ecosystemAllocation = claimData.allocationsData.first {
            $0.allocation.tag.contains("ecosystem")
        }
        let otherAllocations = claimData.allocationsData.filter { item in
            // not one of the found allocations
            !(
                // equal to user allocation
                (item.allocation.vestingId == userAllocation?.allocation.vestingId &&
                 item.allocation.contract == userAllocation?.allocation.contract &&
                 item.allocation.chainId == userAllocation?.allocation.chainId
                ) ||
                // OR equal to ecosystem allocation
                (item.allocation.vestingId == ecosystemAllocation?.allocation.vestingId &&
                 item.allocation.contract == ecosystemAllocation?.allocation.contract &&
                 item.allocation.chainId == ecosystemAllocation?.allocation.chainId
                )
            )
        }

        let isRedeemed = claimData.isRedeemed

        // components and total of vested amount
        let userVestedAmount: Sol.UInt128? = claimData.availableAmount(for: userAllocation, at: timestamp)
        let ecoVestedAmount: Sol.UInt128? = claimData.availableAmount(for: ecosystemAllocation, at: timestamp)
        let otherVestedAmount: Sol.UInt128 = claimData.totalAvailableAmount(of: otherAllocations, at: timestamp)
        let vestedTotal: Sol.UInt128 = claimData.totalAvailableAmount(of: claimData.allocationsData, at: timestamp)
        let availableRange: Range<Sol.UInt128> = vestedTotal > 0 ? (1..<vestedTotal) : (0..<0)

        let vestedValue = formatted(amount: vestedTotal)

        // components and total of unvested amount
        let userUnvestedAmount: Sol.UInt128? = claimData.unvestedAmount(for: userAllocation, at: timestamp)
        let ecoUnvestedAmount: Sol.UInt128? = claimData.unvestedAmount(for: ecosystemAllocation, at: timestamp)
        let otherUnvestedAmount: Sol.UInt128 = claimData.totalUnvestedAmount(of: otherAllocations, at: timestamp)
        let unvestedTotal: Sol.UInt128 = claimData.totalUnvestedAmount(of: claimData.allocationsData, at: timestamp)

        let unvestedValue = formatted(amount: unvestedTotal)

        let (amountTooltipTemplateString, isGuardianAllocationStyle) = templates(
            userAllocation: userAllocation,
            ecosystemAllocation: ecosystemAllocation,
            otherAllocations: otherAllocations
        )

        let vestedAmountTooltip = tooltipString(
            template: amountTooltipTemplateString,
            replacements: [
                "$USER": userVestedAmount,
                "$ECO": ecoVestedAmount,
                "$OTHER": otherVestedAmount
            ]
        )
        let unvestedAmountTooltip = tooltipString(
            template: amountTooltipTemplateString,
            replacements: [
                "$USER": userUnvestedAmount,
                "$ECO": ecoUnvestedAmount,
                "$OTHER": otherUnvestedAmount
            ]
        )

        let darkBoxStyle: AllocationBoxCell.Style = isGuardianAllocationStyle ? .darkGuardian : .darkUser
        let lightBoxStyle: AllocationBoxCell.Style = isGuardianAllocationStyle ? .lightGuardian : .lightUser

        // INFO: this is incorrect for a general case,
        // but for this version of the code we assume all vestings are linear and started on the same date
        let template = "SAFE vesting is vested linearly over $YEARS starting on $START"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let startDate = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2022, month: 9, day: 27))!

        let startDateText = dateFormatter.string(from: startDate)

        let durationTooltip = attributedString(
            template: template,
            replacements: [
                "$YEARS": "4 years",
                "$START": startDateText
            ])


        // Total allocated amount
        let allocatedTotal: Sol.UInt128 = claimData.totalAllocatedAmount(of: claimData.allocationsData, at: timestamp)
        let allocatedValue = formatted(amount: allocatedTotal)
        let allocationText = "Awarded total allocation is \(allocatedValue)."

        return DisplayValues(
            vestedValue: vestedValue,
            vestedAmountTooltip: vestedAmountTooltip,
            vestedStyle: darkBoxStyle,
            unvestedDurationTooltip: durationTooltip,
            unvestedValue: unvestedValue,
            unvestedAmountTooltip: unvestedAmountTooltip,
            unvestedStyle: lightBoxStyle,
            totalValue: allocationText,
            availableRange: availableRange,
            isRedeemed: isRedeemed
        )
    }

    fileprivate func templates(userAllocation: (allocation: Allocation, vesting: ClaimingAppController.Vesting)?, ecosystemAllocation: (allocation: Allocation, vesting: ClaimingAppController.Vesting)?, otherAllocations: [(allocation: Allocation, vesting: ClaimingAppController.Vesting)]) ->  (amountTooltipTemplateString: String, isGuardianAllocationStyle: Bool) {
        let template: String
        let isGuardian: Bool

        // For optional userAllocation, ecosystemAllocation and empty/not empty other allocations
        // we have 8 different cases to handle

        // user != nil, eco != nil, other = empty
        if userAllocation != nil, ecosystemAllocation != nil, otherAllocations.isEmpty {
            template = "This includes user allocation of $USER and Safe guardian allocation of $ECO."
            isGuardian = true
        }
        // user != nil, eco != nil, other = not empty
        else if userAllocation != nil, ecosystemAllocation != nil, !otherAllocations.isEmpty {
            template = "This includes user allocation of $USER, Safe guardian allocation of $ECO, and other allocation of $OTHER."
            isGuardian = true
        }
        // user != nil, eco = nil, other = empty
        else if userAllocation != nil, ecosystemAllocation == nil, otherAllocations.isEmpty {
            template = "Not eligible for Safe Guardian allocation. Contribute to the community to become a Safe Guardian."
            isGuardian = false
        }
        // user != nil, eco = nil, other = not empty
        else if userAllocation != nil, ecosystemAllocation == nil, !otherAllocations.isEmpty {
            template = "This includes user allocation of $USER and other allocation of $OTHER."
            isGuardian = false
        }
        // user = nil, eco != nil, other = empty
        else if userAllocation == nil, ecosystemAllocation != nil, otherAllocations.isEmpty {
            template = "This includes Safe guardian allocation of $ECO."
            isGuardian = true
        }
        // user = nil, eco != nil, other = not empty
        else if userAllocation == nil, ecosystemAllocation != nil, !otherAllocations.isEmpty {
            template = "This includes Safe guardian allocation of $ECO and other allocation of $OTHER."
            isGuardian = true
        }
        // user = nil, eco = nil, other = empty
        else if userAllocation == nil, ecosystemAllocation == nil, otherAllocations.isEmpty {
            template = "Not eligible for SAFE allocations."
            isGuardian = false
        }
        // user = nil, eco = nil, other = not empty
        else if userAllocation == nil, ecosystemAllocation == nil, !otherAllocations.isEmpty {
            template = "Not eligible for user or Safe Guardian allocation. Use Safe and contribute to the community to become a Safe Guardian."
            isGuardian = false
        } else {
            preconditionFailure("Not reachable state")
        }

        return (template, isGuardian)
    }

    func tooltipString(template: String, replacements: [String: Sol.UInt128?]) -> NSAttributedString {
        let replacementItems = replacements.compactMap { key, value -> (String, String)? in
            guard let value = value else { return nil }
            return (key, formatted(amount: value))
        }

        let result = attributedString(
            template: template,
            replacements: Dictionary(uniqueKeysWithValues: replacementItems))
        return result
    }

    func attributedString(
        template: String,
        attributes: [NSAttributedString.Key: Any]? = nil,
        replacements: [String: String],
        replacementAttributes: [NSAttributedString.Key: Any]? = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
    ) -> NSAttributedString {

        let attributedString = NSMutableAttributedString(string: template, attributes: attributes)

        for replacement in replacements {
            let range = (attributedString.string as NSString).range(of: replacement.key)
            guard range.location != NSNotFound else { continue }
            let replacementString = NSAttributedString(string: replacement.value, attributes: replacementAttributes)
            attributedString.replaceCharacters(in: range, with: replacementString)
        }

        return attributedString
    }
}
