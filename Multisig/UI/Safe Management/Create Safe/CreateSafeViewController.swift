//
//  CreateSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class CreateSafeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreateSafeFormUIModelDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var createButton: UIButton!
    private var closeButton: UIBarButtonItem!
    private var refreshControl: UIRefreshControl!

    var onClose: () -> Void = {}
    var onFinish: () -> Void = {}

    private var uiModel = CreateSafeFormUIModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create Safe"

        tableView.registerHeaderFooterView(InfoSectionHeaderView.self)
        tableView.registerCell(SelectNetworkTableViewCell.self)
        tableView.registerCell(ActionDetailAddressCell.self)
        tableView.registerCell(StepperTableViewCell.self)
        tableView.registerCell(DisclosureWithContentCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton

        createButton.setText("Create", .filled)

        uiModel.delegate = self

        uiModel.start()
    }

    // MARK: - UI Model Events

    func updateUI(model: CreateSafeFormUIModel) {
        tableView.reloadData()
        createButton.isEnabled = model.isCreateEnabled
    }

    func createSafeModelDidFinish() {
        // TODO: open next screen!
        onFinish()
    }

    // MARK: - UI Events

    @objc private func didTapCloseButton() {
        onClose()
    }

    @IBAction func didTapCreateButton(_ sender: Any) {
        print("create")
    }

    @objc private func didPullToRefresh() {
        refreshControl.endRefreshing()
    }

    // MARK: - Table View Data and Views

    private func isValid(section: Int) -> Bool {
        section < uiModel.sectionHeaders.count
    }

    private func isValid(indexPath: IndexPath) -> Bool {
        isValid(section: indexPath.section) && indexPath.row < uiModel.sectionHeaders[indexPath.section].itemCount
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        uiModel.sectionHeaders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isValid(section: section) else { return 0 }
        return uiModel.sectionHeaders[section].itemCount
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard isValid(section: section) else { return nil }
        let sectionData = uiModel.sectionHeaders[section]
        let view = tableView.dequeueHeaderFooterView(InfoSectionHeaderView.self)
        view.infoLabel.setText(sectionData.title, description: sectionData.tooltip)
        view.accessoryButton.isHidden = !sectionData.actionable
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isValid(indexPath: indexPath) else { return UITableViewCell() }

        switch uiModel.sectionHeaders[indexPath.section].id {
        case .network:
            let cell = networkCell(for: indexPath)
            return cell
        case .owners:
            let cell = ownerCell(for: indexPath)
            return cell
        case .threshold:
            let cell = thresholdCell(for: indexPath)
            return cell
        case .deployment:
            let cell = deploymentCell(for: indexPath)
            return cell
        case .error:
            let cell = errorCell(for: indexPath)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard isValid(indexPath: indexPath) else { return false }
        let id = uiModel.sectionHeaders[indexPath.section].id
        let canEdit = id == .owners
        return canEdit
    }

    // MARK: - Table View Events

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }

    // MARK: - Cells

    func networkCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(SelectNetworkTableViewCell.self, for: indexPath)
        cell.setText(uiModel.chain.name)
        cell.setIndicatorColor(uiModel.chain.backgroundColor)
        return cell
    }

    func ownerCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ActionDetailAddressCell.self, for: indexPath)
        let owner = uiModel.owners[indexPath.row]
        cell.setAddress(owner.address,
                        label: owner.name,
                        imageUri: owner.imageUri,
                        browseURL: owner.browseUri,
                        prefix: owner.`prefix`)
        return cell
    }

    func thresholdCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(StepperTableViewCell.self, for: indexPath)
        cell.setText(uiModel.thresholdText)
        cell.setRange(min: uiModel.minThreshold, max: uiModel.maxThreshold)
        cell.setValue(uiModel.threshold)
        return cell
    }

    func deploymentCell(for indexPath: IndexPath) -> UITableViewCell {
        let DEPLOYER_ROW = 0
        let FEE_ROW = 1
        switch indexPath.row {
        case DEPLOYER_ROW:
            let cell = deployerAccountCell(for: indexPath)
            return cell

        case FEE_ROW:
            let cell = estimateFeeCell(for: indexPath)
            return cell

        default:
            fatalError("Invalid index path")
        }
    }

    private func deployerAccountCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self, for: indexPath)
        cell.setText("Deploy with")

        if uiModel.isLoadingDeployer {
            let view = loadingView()
            cell.setContent(view)
        } else if let model = uiModel.deployerAccountInfoModel {
            let view = MiniAccountAndBalancePiece()
            view.setModel(model)
            cell.setContent(view)
        } else {
            let view = textView("Key not set")
            cell.setContent(view)
        }
        return cell
    }

    private func estimateFeeCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self, for: indexPath)
        cell.setText("Estimated gas fee")
        if uiModel.isLoadingFee {
            let view = loadingView()
            cell.setContent(view)
        } else if let model = uiModel.estimatedFeeModel {
            let view = AmountAndValuePiece()
            view.setAmount(model.tokenAmount)
            view.setFiatAmount(model.fiatAmount)
            cell.setContent(view)
        } else {
            let view = textView("Not set")
            cell.setContent(view)
        }
        return cell
    }

    private func textView(_ text: String?) -> UIView {
        let label = UILabel()
        label.textAlignment = .right
        label.setStyle(.secondary)
        label.text = text
        return label
    }

    private func loadingView() -> UIView {
        let skeleton = UILabel()
        skeleton.textAlignment = .right
        skeleton.isSkeletonable = true
        skeleton.skeletonTextLineHeight = .fixed(25)
        skeleton.showSkeleton(delay: 0.2)
        return skeleton
    }

    private func errorCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self, for: indexPath)
        // restrict to 1 tweet length
        let errorText = uiModel.error?.localizedDescription ?? ""
        let errorPreview = errorText.count <= 144 ? nil : (String(errorText.prefix(144)) + "…")
        cell.tableView = tableView
        cell.titleStyle = .error.weight(.medium)
        cell.expandableTitleStyle = (collapsed: .error, expanded: .error)
        cell.contentStyle = (collapsed: .error, expanded: .secondary)
        cell.setTitle("⚠️ Error")
        cell.setText(errorText)
        cell.setCopyText(errorText)
        cell.setExpandableTitle(errorPreview)
        return cell
    }
}
