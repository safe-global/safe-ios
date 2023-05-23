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
    @IBOutlet weak var labelContainer: UIStackView!
    @IBOutlet weak var button: UIButton!

    private var stepLabel: UILabel!

    @IBOutlet weak var warningView: WarningView!
    var stepNumber: Int = 1
    var maxSteps: Int = 2
    var minConfirmations: Int = 1
    var maxConfirmations: Int = 1
    var confirmations: Int = 1


    var trackingEvent: TrackingEvent? = nil
    var promptText: String = ""
    var titleText: String = "Change confirmations"
    var completion: ((Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        cellBuilder = SafeCellBuilder(viewController: self, tableView: tableView)

        cellBuilder.registerCells()

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        if promptText.isEmpty {
            labelContainer.isHidden = true

        } else {
            promptLabel.setStyle(.body)
            promptLabel.text = promptText
        }
        button.setText("Continue", .filled)
    }

    @IBAction func didTapButton(_ sender: Any) {
        completion?(confirmations)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    func showWarning() -> Bool {
         confirmations >= maxConfirmations
    }

    // MARK: Table View Content and Events

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showWarning() ? 3 : 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return cellBuilder.thresholdCell(
                    "\(min(confirmations, maxConfirmations)) out of \(maxConfirmations)",
                    range: (minConfirmations...maxConfirmations),
                    value: confirmations,
                    indexPath: indexPath,
                    onChange: { [unowned self] threshold in
                        confirmations = threshold
                        if let cell = tableView.cellForRow(at: indexPath) as? StepperTableViewCell {
                            cell.setText("\(confirmations) out of \(maxConfirmations)")
                        }

                        tableView.reloadData()
                    }
            )
        } else if indexPath.row == 1 {
            return cellBuilder.thresholdHelpCell(for: indexPath)
        } else {
            return cellBuilder.warningCell(image: nil,
                                           title: nil,
                                           description: "We recommend to set a threshold which is lower than the total number of owners of your Safe Account.",
                                           for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        cellBuilder.headerView(text: "Required Confirmations")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else {
            return
        }
        cellBuilder.didSelectThresholdHelpCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BasicHeaderView.headerHeight
    }

}
