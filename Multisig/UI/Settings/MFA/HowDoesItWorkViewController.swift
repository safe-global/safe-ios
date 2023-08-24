//
//  HowDoesItWorkViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/21/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class HowDoesItWorkViewController: UIViewController {
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    enum Step {
        case step(number: String, title: String, description: String)
        case finalStep(title: String)
    }

    private var titleText: String?
    private var actionText: String?
    private var image: String?
    private var steps: [Step] = []
    private var trackingEvent: TrackingEvent?

    var onAction: () -> Void = { }

    convenience init(
        titleText: String?,
        actionText: String?,
        image: String?,
        steps: [Step],
        trackingEvent: TrackingEvent? = nil,
        onDone: @escaping () -> Void
    ) {
        self.init(nibName: nil, bundle: nil)
        self.titleText = titleText
        self.actionText = actionText
        self.image = image
        self.steps = steps
        self.trackingEvent = trackingEvent
        self.onAction = onDone
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.setStyle(.title1)
        titleLabel.text = titleText
        doneButton.setText(actionText, .filled)
        if let image = image {
            imageView.image = UIImage(named: image)
        }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        tableView.registerCell(FinalStepInstructionTableViewCell.self)
        tableView.registerCell(StepInstructionTableViewCell.self)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    @IBAction func doneButtonTouched(_ sender: Any) {
        onAction()
    }
}

extension HowDoesItWorkViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentStep = steps[indexPath.row]
        switch currentStep {
        case let .step(number: number, title: title, description: description):
            let cell = tableView.dequeueCell(StepInstructionTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.separatorInset.left = .greatestFiniteMagnitude
            cell.circleLabel.text = number
            cell.headerLabel.text = title
            cell.descriptionLabel.text = description
            cell.setStyles(headerStyle: .body, verticalBarViewHidden: true, topPadding: 8)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        steps.count
    }
}
