//
//  CreateSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Ethereum

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
        case .deployment:
            selectDeploymentRow(indexPath.row)
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

    func selectDeploymentRow(_ index: Int) {
        switch index {
        case DEPLOYER_ROW:
            selectDeploymentKey()

        case FEE_ROW:
            editParameters()

        default:
            break
        }
    }

    // select deployer
    func selectDeploymentKey() {
        let keys = uiModel.executionKeys()

        if keys.isEmpty {
            let addOwnerVC = AddOwnerFirstViewController()
            addOwnerVC.onSuccess = { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
                self.uiModel.selectedKey = self.uiModel.executionKeys().first
                self.uiModel.didEdit()
            }
            addOwnerVC.showsCloseButton = false
            show(addOwnerVC, sender: self)
            return
        }

        let balancesLoader = DefaultAccountBalanceLoader(chain: uiModel.chain)

        if let tx = uiModel.transaction {
            balancesLoader.requiredBalance = tx.requiredBalance
        }

        let keyPickerVC = ChooseOwnerKeyViewController(
                owners: keys,
                chainID: uiModel.chain.id,
                titleText: "Deployer Account",
                header: .text(description: "The selected account will be used to deploy the Safe."),
                requestsPasscode: false,
                selectedKey: uiModel.selectedKey,
                balancesLoader: balancesLoader
        )
        keyPickerVC.showsCloseButton = false

        // TODO: Tracking on key change
//        keyPickerVC.trackingEvent = .reviewExecutionSelectKey

        // this way of returning the results from the view controller is just because
        // there was already existing code depending on the completion handler.
        // modified with minimum changes to the existing API.
        let completion: (KeyInfo?) -> Void = { [weak self, weak keyPickerVC] selectedKeyInfo in
            guard let self = self, let picker = keyPickerVC else { return }
            let balance = selectedKeyInfo.flatMap { picker.accountBalance(for: $0) }
            let previousKey = self.uiModel.selectedKey

            // update selection
            if let key = selectedKeyInfo, let balance = balance {
                self.uiModel.selectedKey = key
                self.uiModel.deployerBalance = balance.amount
            } else {
                self.uiModel.selectedKey = nil
                self.uiModel.deployerBalance = nil
            }
            if selectedKeyInfo != previousKey {
                // TODO: Tracking on change key
//                Tracker.trackEvent(.reviewExecutionSelectedKeyChanged)
                self.uiModel.didEdit()
            }

            self.navigationController?.popViewController(animated: true)
        }
        keyPickerVC.completionHandler = completion

        show(keyPickerVC, sender: self)
    }

    // edit fees
    func editParameters() {
        let formModel: FormModel
        var initialValues = UserDefinedTransactionParameters()

        if uiModel.userTxParameters == nil {
            uiModel.userTxParameters = initialValues
        }

        switch uiModel.transaction {
        case let ethTx as Eth.TransactionLegacy:
            let model = FeeLegacyFormModel(
                    nonce: ethTx.nonce,
                    minimalNonce: uiModel.minNonce,
                    gas: ethTx.fee.gas,
                    gasPriceInWei: ethTx.fee.gasPrice,
                    nativeCurrency: uiModel.chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.gasPrice = model.gasPriceInWei

            formModel = model

        case let ethTx as Eth.TransactionEip1559:
            let model = Fee1559FormModel(
                    nonce: ethTx.nonce,
                    minimalNonce: uiModel.minNonce,
                    gas: ethTx.fee.gas,
                    maxFeePerGasInWei: ethTx.fee.maxFeePerGas,
                    maxPriorityFeePerGasInWei: ethTx.fee.maxPriorityFee,
                    nativeCurrency: uiModel.chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.maxFeePerGas = model.maxFeePerGasInWei
            initialValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

            formModel = model

        default:
            if uiModel.chain.features?.contains("EIP1559") == true {
                formModel = Fee1559FormModel(
                        nonce: nil,
                        gas: nil,
                        maxFeePerGasInWei: nil,
                        maxPriorityFeePerGasInWei: nil,
                        nativeCurrency: uiModel.chain.nativeCurrency!
                )
            } else {
                formModel = FeeLegacyFormModel(
                        nonce: nil,
                        gas: nil,
                        gasPriceInWei: nil,
                        nativeCurrency: uiModel.chain.nativeCurrency!
                )
            }
        }

        let formVC = FormViewController(model: formModel) { [weak self] in
            // on close - ignore any changes
//            self?.dismiss(animated: true)
            self?.navigationController?.popToRootViewController(animated: true)
        }
        formVC.showsCloseButton = false

        // TODO: tracking of form
//        formVC.trackingEvent = .reviewExecutionEditFee

        formVC.onSave = { [weak self, weak formModel] in
            // on save - update the parameters that were changed.
            self?.navigationController?.popToRootViewController(animated: true)
//            self?.dismiss(animated: true, completion: {
                guard let self = self, let formModel = formModel else { return }

                // collect the saved values

                var savedValues = UserDefinedTransactionParameters()

                switch formModel {
                case let model as FeeLegacyFormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.gasPrice = model.gasPriceInWei

                case let model as Fee1559FormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.maxFeePerGas = model.maxFeePerGasInWei
                    savedValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

                default:
                    break
                }

                // compare the initial snapshot and saved snapshot
                // memberwise and remember only those values that changed.

                var changedFieldTrackingIds: [String] = []

                if savedValues.nonce != initialValues.nonce {
                    self.uiModel.userTxParameters?.nonce = savedValues.nonce

                    changedFieldTrackingIds.append("nonce")
                }

                if savedValues.gas != initialValues.gas {
                    self.uiModel.userTxParameters?.gas = savedValues.gas

                    changedFieldTrackingIds.append("gasLimit")
                }

                if savedValues.gasPrice != initialValues.gasPrice {
                    self.uiModel.userTxParameters?.gasPrice = savedValues.gasPrice

                    changedFieldTrackingIds.append("gasPrice")
                }

                if savedValues.maxFeePerGas != initialValues.maxFeePerGas {
                    self.uiModel.userTxParameters?.maxFeePerGas = savedValues.maxFeePerGas

                    changedFieldTrackingIds.append("maxFee")
                }

                if savedValues.maxPriorityFee != initialValues.maxPriorityFee {
                    self.uiModel.userTxParameters?.maxPriorityFee = savedValues.maxPriorityFee

                    changedFieldTrackingIds.append("maxPriorityFee")
                }

                // react to changes

                if savedValues != initialValues {
                        // take the values only if they were set by user (not nil)
                    switch self.uiModel.transaction {
                    case var ethTx as Eth.TransactionLegacy:
                        ethTx.fee.gas = self.uiModel.userTxParameters?.gas ?? ethTx.fee.gas
                        ethTx.fee.gasPrice = self.uiModel.userTxParameters?.gasPrice ?? ethTx.fee.gasPrice
                        ethTx.nonce = self.uiModel.userTxParameters?.nonce ?? ethTx.nonce

                        self.uiModel.transaction = ethTx

                    case var ethTx as Eth.TransactionEip1559:
                        ethTx.fee.gas = self.uiModel.userTxParameters?.gas ?? ethTx.fee.gas
                        ethTx.fee.maxFeePerGas = self.uiModel.userTxParameters?.maxFeePerGas ?? ethTx.fee.maxFeePerGas
                        ethTx.fee.maxPriorityFee = self.uiModel.userTxParameters?.maxPriorityFee ?? ethTx.fee.maxPriorityFee
                        ethTx.nonce = self.uiModel.userTxParameters?.nonce ?? ethTx.nonce

                        self.uiModel.transaction = ethTx

                    default:
                        break
                    }
                    self.uiModel.didEdit()
                    // TODO: track changes
//                    let changedFields = changedFieldTrackingIds.joined(separator: ",")
//                    Tracker.trackEvent(.reviewExecutionFieldEdited, parameters: ["fields": changedFields])
                }
//            })
        }

        formVC.navigationItem.title = "Edit transaction fee"
        let ribbon = RibbonViewController(rootViewController: formVC)
//        let nav = UINavigationController(rootViewController: ribbon)
//        present(nav, animated: true, completion: nil)
        show(ribbon, sender: self)
    }

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
        cell.onChange = { [weak self, unowned cell] newThreshold in
            guard let self = self else { return }
            self.uiModel.threshold = newThreshold
            cell.setText(self.uiModel.thresholdText)
            self.uiModel.didEdit()
        }
        return cell
    }

    let DEPLOYER_ROW = 0
    let FEE_ROW = 1

    func deploymentCell(for indexPath: IndexPath) -> UITableViewCell {
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
