//
//  CreateRecoveryKitSuccessViewController.swift
//  Multisig
//
//  Created by Mouaz on 8/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

fileprivate protocol SectionItem {}

class UpdateRecoveryKitSuccessViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var animationView: LottieAnimationView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var primaryButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    private var titleText: String?
    private var bodyText: String?
    private var primaryAction: String?

    private var trackingEvent: TrackingEvent?

    var onDone: () -> Void = { }

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()

    enum Section {
        case factor

        enum Factor: SectionItem {
            case factor(String, String?, String, Bool, Bool)
        }
    }

    convenience init(
        titleText: String?,
        bodyText: String?,
        primaryAction: String?,
        trackingEvent: TrackingEvent? = nil,
        onDone: @escaping () -> Void
    ) {
        self.init(nibName: nil, bundle: nil)
        self.titleText = titleText
        self.bodyText = bodyText
        self.primaryAction = primaryAction
        self.trackingEvent = trackingEvent
        self.onDone = onDone
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.title1)
        bodyLabel.setStyle(.body)

        tableView.registerCell(SecurityFactorTableViewCell.self)

        tableView.separatorStyle = .none
        tableView.rowHeight = SecurityFactorTableViewCell.rowHeight

        tableView.tableFooterView = UIView()

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        titleLabel.text = titleText
        bodyLabel.text = bodyText

        primaryButton.setText(primaryAction, .filled)

        animationView.animation = LottieAnimation.named(isDarkMode ? "successAnimationDark" : "successAnimation",
                                                  animationCache: nil)
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
        buildSections()
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    @IBAction func didTapDone(_ sender: Any) {
        onDone()
    }

    private func buildSections() {
        sections = []

        // TODO: Build sections properly
        sections.append(SectionItems(section: .factor, items: [
            Section.Factor.factor("Email address", "ann.fischer@gmail", "ico-eMail", true, true),
            Section.Factor.factor("Trusted device", nil, "ico-mobile", false, true),
            Section.Factor.factor("Security password", nil, "ico-password", false, true)]))
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let factor = sections[indexPath.section].items[indexPath.row]
        switch sections[indexPath.section].section {
        case .factor:
            if case let Section.Factor.factor(name, value, image, isDefault, selected) = factor {
                let cell = tableView.dequeueCell(SecurityFactorTableViewCell.self, for: indexPath)
                //cell.selectionStyle = .none
                cell.set(name: name,
                         icon: UIImage(named: image)!,
                         value: value,
                         tag: isDefault ? "(Default)" : nil,
                         selected: selected,
                         showDisclosure: false,
                         bordered: true)
                cell.backgroundColor = .clear
                return cell
            }
        }
        
        return UITableViewCell()
    }
}
