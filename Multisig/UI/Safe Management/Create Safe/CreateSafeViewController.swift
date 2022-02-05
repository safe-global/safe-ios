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

    func authenticateUser(_ completion: @escaping (Bool) -> Void) {
        // show passcode
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

    @objc private func didTapAddOwnerButton(_ sender: Any) {
        addOwner()
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
        if view.accessoryButton.allTargets.isEmpty {
            view.accessoryButton.addTarget(nil, action: #selector(didTapAddOwnerButton(_:)), for: .touchUpInside)
        }
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
        guard isValid(indexPath: indexPath) else { return }
        switch uiModel.sectionHeaders[indexPath.section].id {
        case .network:
            selectNetwork()
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        uiModel.deleteOwnerAt(indexPath.row)
    }

    // select network
    func selectNetwork() {
        // show network selection screen
        let selectNetworkVC = SelectNetworkViewController()
        selectNetworkVC.screenTitle = "Select Network"
        selectNetworkVC.descriptionText = "Choose a network on which to create your Safe"
        // get the selected network back
        selectNetworkVC.completion = { [weak self] chain in
            guard let self = self else { return }
            self.uiModel.setChainId(chain.id)

            // hide the screen
            self.navigationController?.popViewController(animated: true)
        }
        show(selectNetworkVC, sender: self)
    }

    func addOwner() {
        // add address using existing methods
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertVC.addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: { [weak self] _ in
            let text = Pasteboard.string
            self?.didAddOwnerAddress(text)
        }))

        alertVC.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let vc = QRCodeScannerViewController()
            vc.scannedValueValidator = { value in
                if let _ = try? Address.addressWithPrefix(text: value) {
                    return .success(value)
                } else {
                    return .failure(GSError.error(description: "Can’t use this QR code",
                            error: GSError.SafeAddressNotValid()))
                }
            }
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.setup()
            self.present(vc, animated: true, completion: nil)
        }))

        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertVC, animated: true, completion: nil)
    }

    func didAddOwnerAddress(_ string: String?) {
        uiModel.addOwnerAddress(string)
    }

    // change threshold
        // connect the stepper to the label
        // connect stepper's max and min to the uimodel's max and min
        // did it change value? notify the model about editing

    // select deployer
        // show deployers with balances
        // did it change? notify the model

    // edit fees
        // use the fee form or generalize it somehow
        // load existing user defined properties merged with the transaction values, i.e. updated transaction value.
        // create form fields
        // saved - has changes from the initial values? which? save them. notify the model.

    // create button tapped
        // notify the model

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

extension CreateSafeViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        didAddOwnerAddress(code)
        dismiss(animated: true, completion: nil)
    }
}
