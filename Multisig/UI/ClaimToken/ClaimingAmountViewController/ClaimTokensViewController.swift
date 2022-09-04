//
//  ClaimingAmountViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/29/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftCryptoTokenFormatter

class ClaimTokensViewController: LoadableViewController {
    // TODO: nice-to-have: make tooltip a bit narrower so that the text reads better; + dark mode version of tooltip

    enum RowItem {
        case claimableNow
        case claimableFuture
        case claimableTotal
        case claimingAmount
        case selectedDelegate
    }

    private var stepNumber: Int = 3
    private var maxSteps: Int = 4

    private var guardian: Guardian!
    private var safe: Safe!
    private var claimingAmount: SafeClaimingAmount!

    private var onClaim: ((Guardian, String) -> ())?

    private var stepLabel: UILabel!
    private var claimButtonContainer: UIView!
    private var claimButton: UIButton!
    private var claimButtonBottom: NSLayoutConstraint!
    private var keyboardBehavior: KeyboardAvoidingBehavior!


    private var rows: [RowItem] = [.claimableNow, .claimableFuture, .claimableTotal, .claimingAmount, .selectedDelegate]

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
        title = "Your SAFE allocation"

        claimingAmount = SafeClaimingController.shared.claimingAmountFor(safe: safe.addressValue)
        assert(claimingAmount != nil)

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
        // hide all tooltips?
        // fetch all data
            // update amounts available, claimed, tooltip texts
            //
    }

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
            let cell = tableView.dequeueCell(ClaimedAmountInputCell.self)
            cell.maxValue = tokenFormatter.string(from: claimingAmount.totalClaimable)
            return cell

        case .selectedDelegate:
            let cell = tableView.dequeueCell(SelectedDelegateCell.self)
            cell.guardian = guardian
            return cell
        }
    }
}
