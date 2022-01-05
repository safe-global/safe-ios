//
//  ReviewSendFundsTransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version

fileprivate protocol SectionItem {}

class ReviewSendFundsTransactionViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedLabel: UILabel!
    @IBOutlet private weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var estimationFailedDescriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedView: UIView!
    @IBOutlet private weak var contentContainerView: UIView!

    private var currentDataTask: URLSessionTask?
    var address: Address!
    var amount: String!
    var safe: Safe!

    enum Section {
        case basic
        case advanced

        enum Basic: SectionItem {
            case safe(UITableViewCell)
            case transaction(UITableViewCell)
            case data(UITableViewCell)
            case advanced(UITableViewCell)
        }

        enum Advanced: SectionItem {
            case nonce(UITableViewCell)
            case safeTxGas(UITableViewCell)
            case edit(UITableViewCell)
        }
    }

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()
    private var isAdvancedOptionsShown = false

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(address != nil)
        assert(amount != nil)
        assert(safe != nil)

        navigationItem.title = "Review"
        confirmButton.setText("Confirm", .filled)
        retryButton.setText("Retry", .filled)
        descriptionLabel.setStyle(.footnote2)

        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(EditCell.self)

        tableView.estimatedRowHeight = BasicCell.rowHeight

        loadData()
    }

    @IBAction func confirmButtonTouched(_ sender: Any) {

    }

    @IBAction func retryButtonTouched(_ sender: Any) {
        loadData()
    }

    private func loadData() {
        startLoading()
        currentDataTask?.cancel()
        currentDataTask = App.shared.clientGatewayService.asyncTransactionEstimation(chainId: safe.chain!.id!,
                                                                   safeAddress: safe.addressValue,
                                                                   to: address,
                                                                   value: 0,
                                                                   data: nil,
                                                                   operation: .call) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.endLoading()
                self.buildSections()
                self.tableView.reloadData()
            }
        }
    }

    private func startLoading() {
        loadingActivityIndicator.isHidden = false
        loadingActivityIndicator.startAnimating()
        contentContainerView.isHidden = true
    }

    private func endLoading() {
        loadingActivityIndicator.isHidden = true
        loadingActivityIndicator.stopAnimating()
        contentContainerView.isHidden = false
    }

    private func buildSections() {
        var advancedSectionItems = [SectionItem]()
        if isAdvancedOptionsShown {
            advancedSectionItems.append(
                Section.Advanced.nonce(infoCell(title: "Safe nonce", value: "transaction.nonce.description"))
            )

            let version = Version(safe.contractVersion!)!
            if version < Version(1, 3, 0) {
                advancedSectionItems.append(
                    Section.Advanced.safeTxGas(infoCell(title: "SafeTxGas", value: "transaction.safeTxGas.description"))
                )
            }

            advancedSectionItems.append(
                Section.Advanced.edit(editCell())
            )
        }
        sections = [
            (section: .basic, items: [
                Section.Basic.safe(safeCell()),
                Section.Basic.advanced(advancedCell())
            ]),
            (section: .advanced, items: advancedSectionItems)
        ]
    }

    private func reloadAdvancedSection() {
        buildSections()

        tableView.beginUpdates()
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .automatic)

        var advancedRows = [IndexPath]()
        let version = Version(safe.contractVersion!)!
        let advancedRowsCount = version < Version(1, 3, 0) ? 3 : 2

        for index in 0..<advancedRowsCount {
            advancedRows.append(IndexPath(row: index, section: 1))
        }

        if isAdvancedOptionsShown {
            tableView.insertRows(at: advancedRows, with: .bottom)
        } else {
            tableView.deleteRows(at: advancedRows, with: .fade)
        }
        tableView.endUpdates()
    }

    private func safeCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        let chain = safe.chain!

        cell.setAccount(
            address: safe!.addressValue,
            label: Safe.cachedName(by: safe.address!, chainId: chain.id!),
            title: "Connected safe",
            browseURL: chain.browserURL(address: address.checksummed),
            prefix: chain.shortName
        )
        cell.selectionStyle = .none
        return cell
    }

//    private func transactionCell() -> UITableViewCell {
//        let cell = tableView.dequeueCell(DetailTransferInfoCell.self)
//        let chain = safe.chain!
//
//        let coin = chain.nativeCurrency!
//        let decimalAmount = BigDecimal(
//            Int256(transaction.value.value) * -1,
//            Int(coin.decimals)
//        )
//        let amount = TokenFormatter().string(
//            from: decimalAmount,
//            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
//            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ","
//        )
//        let tokenText = "\(amount) \(coin.symbol!)"
//        let tokenDetail = amount == "0" ? "\(transaction.data?.data.count ?? 0) Bytes" : nil
//        let (addressName, _) = NamingPolicy.name(for: transaction.to.address,
//                                                    info: nil,
//                                                    chainId: safe.chain!.id!)
//
//        cell.setToken(text: tokenText, style: .secondary)
//        cell.setToken(image: coin.logoUrl)
//        cell.setDetail(tokenDetail)
//
//        cell.setAddress(transaction.to.address,
//                        label: addressName,
//                        imageUri: nil,
//                        browseURL: chain.browserURL(address: transaction.to.address.checksummed),
//                        prefix: chain.shortName)
//        cell.setOutgoing(true)
//        cell.selectionStyle = .none
//
//        return cell
//    }

    private func advancedCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self)
        cell.setTitle("Advanced")
        cell.setIcon(nil)
        let image = UIImage(systemName: isAdvancedOptionsShown ? "chevron.up" : "chevron.down")!
            .applyingSymbolConfiguration(.init(weight: .bold))!
        cell.setDisclosureImage(image)
        cell.setDisclosureImageTintColor(.secondaryLabel)
        cell.selectedBackgroundView = UIView()
        return cell
    }

    private func infoCell(title: String, value: String) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self)
        cell.setTitle(title)
        cell.setInfo(value)
        cell.selectionStyle = .none
        return cell
    }

    private func editCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(EditCell.self)
        cell.onEdit = { [unowned self] in
            self.showEditParameters()
        }
        cell.selectionStyle = .none
        return cell
    }

    private func showEditParameters() {
        let vc = advanced
//        let safeTxGas = transaction.safeVersion! >= Version(1, 3, 0) ? nil : transaction.safeTxGas
//        let editParamsController = WCEditParametersViewController.create(nonce: transaction.nonce,
//                                                                         minimalNonce: minimalNonce,
//                                                                         safeTxGas: safeTxGas,
//                                                                         trackingParameters: trackingParameters) {
//            [unowned self] nonce, safeTxGas in
//            self.transaction.nonce = nonce
//            if let safeTxGas = safeTxGas {
//                self.transaction.safeTxGas = safeTxGas
//            }
//            self.transaction.updateSafeTxHash()
//            self.buildSections()
//            self.tableView.reloadData()
//        }
//        let navController = UINavigationController(rootViewController: editParamsController)
//        present(navController, animated: true, completion: nil)
    }
}

extension ReviewSendFundsTransactionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.safe(let cell): return cell
        case Section.Basic.transaction(let cell): return cell
        case Section.Basic.data(let cell): return cell
        case Section.Basic.advanced(let cell): return cell
        case Section.Advanced.nonce(let cell): return cell
        case Section.Advanced.safeTxGas(let cell): return cell
        case Section.Advanced.edit(let cell): return cell
        default: return UITableViewCell()
        }
    }
}

extension ReviewSendFundsTransactionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].items[indexPath.row] {

        case Section.Basic.advanced(_):
            tableView.deselectRow(at: indexPath, animated: true)
            isAdvancedOptionsShown.toggle()
            reloadAdvancedSection()

        case Section.Advanced.edit(_):
            showEditParameters()

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.advanced(_): return BasicCell.rowHeight
        default: return UITableView.automaticDimension
        }
    }
}
