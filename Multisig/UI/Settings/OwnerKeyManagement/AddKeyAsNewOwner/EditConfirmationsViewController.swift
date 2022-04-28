//
//  EditConfirmationsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class EditConfirmationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var cellBuilder: SafeCellBuilder!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    private var stepLabel: UILabel!

    var stepNumber: Int = 1
    var maxSteps: Int = 2
    var minConfirmations: Int = 1
    var maxConfirmations: Int = 1
    var confirmations: Int = 1

    var trackingEvent: TrackingEvent? = nil

    var completion: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Change confirmations"

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        cellBuilder = SafeCellBuilder(viewController: self, tableView: tableView)

        cellBuilder.registerCells()

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        promptLabel.setStyle(.secondary)
        promptLabel.text = "You’re about to add an owner. Would you like to change the required confirmations?"

        button.setText("Continue", .filled)
    }

    @IBAction func didTapButton(_ sender: Any) {
        completion?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            
        }
    }

    // MARK: Table View Content and Events

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return cellBuilder.thresholdCell(
                "\(confirmations) out of \(maxConfirmations)",
                range: (minConfirmations...maxConfirmations),
                value: confirmations,
                indexPath: indexPath,
                onChange: { [unowned self] threshold in
                    confirmations = threshold
                    if let cell = tableView.cellForRow(at: indexPath) as? StepperTableViewCell {
                        cell.setText("\(confirmations) out of \(maxConfirmations)")
                    }
                }
            )
        } else {
            return cellBuilder.thresholdHelpCell(for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        cellBuilder.headerView(text: "Required Confirmations")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else { return }
        cellBuilder.didSelectThresholdHelpCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BasicHeaderView.headerHeight
    }

}
