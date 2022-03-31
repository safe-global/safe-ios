//
//  CreateSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Ethereum
import Solidity
import WalletConnectSwift

class CreateSafeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreateSafeFormUIModelDelegate {

    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var createButton: UIButton!
    private var refreshControl: UIRefreshControl!

    var onClose: () -> Void = {}

    private var uiModel = CreateSafeFormUIModel()
    var txHash: String?
    var chain: Chain?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create Safe"

        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerCell(SelectNetworkTableViewCell.self)
        tableView.registerCell(ActionDetailAddressCell.self)
        tableView.registerCell(StepperTableViewCell.self)
        tableView.registerCell(DisclosureWithContentCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(IconButtonTableViewCell.self)
        tableView.registerCell(HelpTextTableViewCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(BorderedInnerTableCell.self)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        createButton.setText("Create Safe", .filled)

        captionLabel.setStyle(.footnote2.weight(.regular))
        captionLabel.text = "Creating a Safe may take a few minutes."

        uiModel.delegate = self
        if let txHash = txHash,
            let chain = chain,
            let safeCreationCall = SafeCreationCall.by(txHashes: [txHash], chainId: chain.id!)?.first {
            uiModel.updateWithSafeCall(call: safeCreationCall)
        }

        if let chain = chain {
            uiModel.chain = chain
        }

        uiModel.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.createSafeOnePage)
    }
    
    // MARK: - UI Model Events

    func updateUI(model: CreateSafeFormUIModel) {
        tableView.reloadData()
        createButton.isEnabled = model.isCreateEnabled
    }

    func createSafeModelDidFinish() {
        onClose()
    }

    // MARK: - UI Events

    override func closeModal() {
        onClose()
    }

    @IBAction func didTapCreateButton(_ sender: Any) {
        userDidSubmit()
    }

    @objc private func didPullToRefresh() {
        refreshControl.endRefreshing()
        uiModel.didEdit()
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
        switch sectionData.id {
        case .error:
            return nil
        default:
            let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
            view.setName(sectionData.title)
            return view
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard isValid(section: section) else { return 0 }
        let sectionData = uiModel.sectionHeaders[section]
        switch sectionData.id {
        case .error:
            return 0
        default:
            return BasicHeaderView.headerHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard isValid(indexPath: indexPath) else { return 0 }
        let sectionId = uiModel.sectionHeaders[indexPath.section].id
        switch sectionId {
        case .owners where !uiModel.owners.isEmpty && indexPath.row < uiModel.owners.count:
            return 68

        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard isValid(indexPath: indexPath) else { return UITableViewCell() }

        switch uiModel.sectionHeaders[indexPath.section].id {
        case .name:
            if let name = uiModel.name {
                return tableView.basicCell(name: name, indexPath: indexPath)
            } else {
                let cell = tableView.basicCell(name: "", indexPath: indexPath)
                cell.setTitle("Enter name", style: .secondary)
                return cell
            }
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
        let canEdit = id == .owners && !uiModel.owners.isEmpty && indexPath.row < uiModel.owners.count
        return canEdit
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        guard isValid(indexPath: indexPath) else { return nil }
        let id = uiModel.sectionHeaders[indexPath.section].id
        guard id == .owners else { return nil }
        return "Remove owner"
    }

    // MARK: - Table View Events

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard isValid(indexPath: indexPath) else { return }
        switch uiModel.sectionHeaders[indexPath.section].id {
        case .name:
            changeName()
        case .network:
            selectNetwork()

        case .owners:
            selectOwnerRow(tableView: tableView, indexPath: indexPath)

        case .threshold:
            selectConfirmationRow(indexPath.row)

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        uiModel.deleteOwnerAt(indexPath.row)
    }

    func changeName() {
        let editSafeNameViewController = EditSafeNameViewController()
        editSafeNameViewController.name = uiModel.name
        editSafeNameViewController.completion = { name in
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.uiModel.setName(name)
                self.navigationController?.popViewController(animated: true)
            }
        }
        show(editSafeNameViewController, sender: self)
    }

    // select network
    func selectNetwork() {
        // show network selection screen
        let selectNetworkVC = SelectNetworkViewController()
        selectNetworkVC.screenTitle = "Select Network"
        selectNetworkVC.descriptionText = "Choose a network on which to create your Safe"
        selectNetworkVC.trackingEvent = .createSafeSelectNetwork
        // get the selected network back
        selectNetworkVC.completion = { [weak self] chain in
            guard let self = self else { return }
            self.uiModel.setChain(chain)
            self.chain = seld

            // hide the screen
            self.navigationController?.popViewController(animated: true)
        }
        show(selectNetworkVC, sender: self)
    }

    func selectOwnerRow(tableView: UITableView, indexPath: IndexPath) {
        guard indexPath.row == uiModel.owners.count else { return }
        addOwner(tableView: tableView, indexPath: indexPath)
    }

    func addOwner(tableView: UITableView, indexPath: IndexPath) {
        let picker = SelectAddressViewController(chain: uiModel.chain, presenter: self) { [weak self] address in
            self?.uiModel.addOwnerAddress(address)
        }

        if let popoverPresentationController = picker.popoverPresentationController {
            popoverPresentationController.sourceView = tableView.cellForRow(at: indexPath)
        }
        present(picker, animated: true, completion: nil)
    }

    func selectConfirmationRow(_ rowIndex: Int) {
        guard rowIndex == 1 else { return }
        openInSafari(App.configuration.help.confirmationsURL)
    }

    // select deployer
    func selectDeploymentKey() {
        let keys = uiModel.executionKeys()

        if keys.isEmpty {
            let addOwnerVC = AddOwnerFirstViewController()
            addOwnerVC.trackingEvent = .createSafeAddDeploymentKey
            addOwnerVC.onSuccess = { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popToViewController(self, animated: true)
                self.uiModel.selectedKey = self.uiModel.executionKeys().first
                self.uiModel.didEdit()
                Tracker.trackEvent(.createSafeDeploymentKeyAdded)
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
        keyPickerVC.trackingEvent = .createSafeSelectKey
        keyPickerVC.showsCloseButton = false

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
                self.uiModel.didEdit()
                Tracker.trackEvent(.createSafeKeyChanged)
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
            self?.dismiss(animated: true)
        }

        formVC.trackingEvent = .createSafeEditTxFee
        formVC.chainId = uiModel.chain.id

        formVC.onSave = { [weak self, weak formModel] in
            // on save - update the parameters that were changed.
            self?.dismiss(animated: true, completion: {
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
                    self.uiModel.userTxParameters.nonce = savedValues.nonce

                    changedFieldTrackingIds.append("nonce")
                }

                if savedValues.gas != initialValues.gas {
                    self.uiModel.userTxParameters.gas = savedValues.gas

                    changedFieldTrackingIds.append("gasLimit")
                }

                if savedValues.gasPrice != initialValues.gasPrice {
                    self.uiModel.userTxParameters.gasPrice = savedValues.gasPrice

                    changedFieldTrackingIds.append("gasPrice")
                }

                if savedValues.maxFeePerGas != initialValues.maxFeePerGas {
                    self.uiModel.userTxParameters.maxFeePerGas = savedValues.maxFeePerGas

                    changedFieldTrackingIds.append("maxFee")
                }

                if savedValues.maxPriorityFee != initialValues.maxPriorityFee {
                    self.uiModel.userTxParameters.maxPriorityFee = savedValues.maxPriorityFee

                    changedFieldTrackingIds.append("maxPriorityFee")
                }

                // react to changes

                if savedValues != initialValues {
                    self.uiModel.error = nil
                    self.uiModel.updateEthTransactionWithUserValues()
                    self.uiModel.didEdit()

                    let changedFields = changedFieldTrackingIds.joined(separator: ",")
                    Tracker.trackEvent(.createSafeTxFeeEdited, parameters: ["fields": changedFields])
                }
            })
        }

        formVC.navigationItem.title = "Edit transaction fee"
        let ribbon = RibbonViewController(rootViewController: formVC)
        ribbon.storedChain = uiModel.chain
        let nav = UINavigationController(rootViewController: ribbon)
        present(nav, animated: true, completion: nil)
    }

    // create button tapped
        // notify the model

    // MARK: - Cells

    func networkCell(for indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(SelectNetworkTableViewCell.self, for: indexPath)
            cell.setText(uiModel.chain.name)
            cell.setIndicatorColor(uiModel.chain.backgroundColor)
            return cell
        case 1:
            let cell = helpTextCell("Safe will only exist on the selected network.", indexPath: indexPath)
            return cell
        default:
            assertionFailure("Developer error: row count should be only two")
            return UITableViewCell()
        }
    }

    func ownerCell(for indexPath: IndexPath) -> UITableViewCell {
        if !uiModel.owners.isEmpty && indexPath.row < uiModel.owners.count {
            let cell = tableView.dequeueCell(ActionDetailAddressCell.self, for: indexPath)
            let owner = uiModel.owners[indexPath.row]
            cell.setAddress(owner.address,
                            label: owner.name,
                            imageUri: owner.imageUri,
                            browseURL: owner.browseUri,
                            prefix: owner.`prefix`,
                            badgeName: owner.badgeName)
            cell.separatorInset = .zero
            return cell
        } else {
            let buttonCellIndex = 0
            let helpTextIndex = 1
            let rowIndex = indexPath.row - uiModel.owners.count
            switch rowIndex {
            case buttonCellIndex:
                let cell = tableView.dequeueCell(IconButtonTableViewCell.self, for: indexPath)
                cell.setImage(UIImage(systemName: "plus.circle"))
                cell.setText("Add Owner")
                return cell

            case helpTextIndex:
                return helpTextCell("Add an owner by pasting or scanning an Ethereum address.", indexPath: indexPath)

            default:
                return UITableViewCell()
            }
        }
    }

    func helpTextCell(_ text: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(HelpTextTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.setText(text)
        return cell
    }

    func helpTextCell(_ text: String, hyperlink: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(HelpTextTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.cellLabel.hyperLinkLabel(
            text,
            prefixStyle: .footnote2.weight(.regular),
            linkText: hyperlink,
            linkStyle: .footnote2.weight(.regular).color(.button),
            linkIcon: nil)
        return cell
    }

    func thresholdCell(for indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueCell(StepperTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
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
        } else {
            let text = "How many owner confirmations are required for a transaction to be executed?"
            let link = "Learn about Safe setup"
            return helpTextCell(text, hyperlink: link, indexPath: indexPath)
        }
    }

    func deploymentCell(for indexPath: IndexPath) -> UITableViewCell {
        // create a table inner cell with other cells
        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self, for: indexPath)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)
        tableCell.tableView.registerCell(SecondaryDetailDisclosureCell.self)

        let accountCell = deployerAccountCell(tableView: tableCell.tableView)
        let estimatedFeeCell = estimateFeeCell(tableView: tableCell.tableView)

        tableCell.setCells([accountCell, estimatedFeeCell])

        // handle cell taps
        let (executeWithIndex, feeIndex) = (0, 1)
        tableCell.onCellTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case executeWithIndex:
                self.selectDeploymentKey()
            case feeIndex:
                self.editParameters()
            default:
                assertionFailure("Tapped cell at index out of bounds: \(index)")
            }
        }

        return tableCell
    }
    private func deployerAccountCell(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Pay with")

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

    private func estimateFeeCell(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Network fee")
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

        cell.tableView = tableView
        cell.titleStyle = .error.weight(.medium)
        cell.expandableTitleStyle = (collapsed: .error, expanded: .error)
        cell.contentStyle = (collapsed: .error, expanded: .error)

        let errorText = uiModel.error?.localizedDescription ?? ""
        let title = errorText.count <= 144 ? errorText : nil
        let errorPreview = errorText.count <= 144 ? nil : (String(errorText.prefix(144)) + "…")
        let errorContent = errorText.count <= 144 ? nil : errorText

        cell.setTitle(title)
        cell.setText(errorContent ?? "")
        cell.setExpandableTitle(errorPreview)
        cell.set(isExpandable: title == nil)
        cell.setCopyText(errorText)

        return cell
    }

    func userDidSubmit() {
        // request passcode if needed and sign
        if App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            let passcodeVC = EnterPasscodeViewController()
            passcodeVC.passcodeCompletion = { [weak self] success, reset in
                self?.dismiss(animated: true) {
                    guard let `self` = self else { return }

                    if success {
                        self.sign()
                    } else if reset {
                        self.dismiss(animated: false, completion: nil)
                    }
                }
            }
            let nav = UINavigationController(rootViewController: passcodeVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            sign()
        }
    }

    func sign() {
        guard let keyInfo = uiModel.selectedKey else { return }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let txHash = uiModel.transaction.hashForSigning().storage.storage

                guard let pk = try keyInfo.privateKey() else {
                    App.shared.snackbar.show(message: "Private key not available")
                    return
                }
                let signature = try pk._store.sign(hash: Array(txHash))

                try uiModel.transaction.updateSignature(
                    v: Sol.UInt256(signature.v),
                    r: Sol.UInt256(Data(signature.r)),
                    s: Sol.UInt256(Data(signature.s))
                )
            } catch {
                let gsError = GSError.error(description: "Signing failed", error: error)
                App.shared.snackbar.show(error: gsError)
                return
            }
            submit()

        case .walletConnect:
            guard let clientTx = walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            let sendTxVC = SendTransactionToWalletViewController(
                transaction: clientTx,
                keyInfo: keyInfo,
                chain: uiModel.chain
            )
            sendTxVC.onCancel = { [weak self] in
                self?.uiModel.didSubmitFailed(nil)
            }
            sendTxVC.onSuccess = { [weak self] txHashData in
                guard let self = self else { return }
                self.uiModel.didSubmitTransaction(txHash: Eth.Hash(txHashData))
                self.uiModel.didSubmitSuccess()
            }
            let vc = ViewControllerFactory.pageSheet(viewController: sendTxVC, halfScreen: true)
            present(vc, animated: true)

        case .ledgerNanoX:
            let rawTransaction = uiModel.transaction.preImageForSigning()
            let chainId = Int(uiModel.chain.id!)!
            let isLegacy = uiModel.transaction is Eth.TransactionLegacy

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak self] signature in
                guard let self = self else { return }

                do {
                    try self.uiModel.transaction.updateSignature(
                        v: Sol.UInt256(UInt(signature.v)),
                        r: Sol.UInt256(Data(Array(signature.r))),
                        s: Sol.UInt256(Data(Array(signature.s)))
                    )
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                self.submit()
            }

            present(vc, animated: true, completion: nil)
        }
    }

    func walletConnectTransaction() -> Client.Transaction? {
        guard let ethTransaction = uiModel.transaction else {
            return nil
        }
        let clientTx: Client.Transaction

        // NOTE: only legacy parameters seem to work with current wallets.
        switch ethTransaction {
        case let tx as Eth.TransactionLegacy:
            let rpcTx = EthRpc1.TransactionLegacy(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip2930:
            let rpcTx = EthRpc1.Transaction2930(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip1559:
            let rpcTx = EthRpc1.Transaction1559(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.maxFeePerGas?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )
        default:
            return nil
        }

        return clientTx
    }


    func submit() {
        uiModel.userDidSubmit()
    }

}
