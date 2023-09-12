//
//  TransactionListViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftCryptoTokenFormatter

class TransactionListViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService

    private var loadFirstPageDataTask: URLSessionTask?
    private var loadNextPageDataTask: URLSessionTask?

    private var model = FlatTransactionsListViewModel()

    internal var safe: Safe!

    internal var trackingEvent: TrackingEvent?
    internal var emptyText: String = "Transactions will appear here"
    internal var emptyImage: UIImage = UIImage(named: "ico-no-transactions")!

    internal var dateFormatter: DateFormatter! = DateFormatter()

    internal var timeFormatter: DateFormatter! = DateFormatter()

    override var isEmpty: Bool {
        model.isEmpty
    }

    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .backgroundPrimary

        tableView.registerCell(TransactionListTableViewCell.self)
        tableView.registerCell(TransactionListHeaderTableViewCell.self)
        tableView.registerCell(TransactionsListConflictHeaderTableViewCell.self)

        tableView.registerHeaderFooterView(IdleFooterView.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.registerHeaderFooterView(RetryFooterView.self)

        tableView.sectionHeaderHeight = TransactionListHeaderTableViewCell.headerHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setTitle(emptyText)
        emptyView.setImage(emptyImage)

        for notification in [Notification.Name.transactionDataInvalidated, .ownerKeyImported, .ownerKeyRemoved, .chainInfoChanged] {
            notificationCenter.addObserver(
                self,
                selector: #selector(lazyReloadData),
                name: notification,
                object: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }

    override func reloadData() {
        super.reloadData()
        loadFirstPageDataTask?.cancel()
        loadNextPageDataTask?.cancel()
        pageLoadingState = .idle

        loadFirstPageDataTask = asyncTransactionList { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    // ignore cancellation error due to cancelling the
                    // currently running task. Otherwise user will see
                    // meaningless message.
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        return
                    }
                    self.onError(GSError.error(description: "Failed to load transactions", error: error))
                }
            case .success(let page):
                var model = FlatTransactionsListViewModel(page.results)
                model.next = page.next

                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }

                    let transformer = TransactionDataTransformer(safe: self.safe, chain: self.safe.chain!)
                    model.items = transformer.transformed(list: model.items)

                    self.model = model
                    self.onSuccess()
                }
            }
        }
    }

    func asyncTransactionList(completion: @escaping (Result<Page<SCGModels.TransactionSummaryItem>, Error>) -> Void) -> URLSessionTask? {
        // Should be overrided in subclass
        nil
    }

    func asyncTransactionList(pageUri: String, completion: @escaping (Result<Page<SCGModels.TransactionSummaryItem>, Error>) -> Void) throws -> URLSessionTask? {
        // Should be overrided in subclass
        nil
    }

    func localized(header: String) -> String {
        header
    }

    enum LoadingState {
        case idle, loading, retry
    }

    var pageLoadingState = LoadingState.idle {
        didSet {
            switch pageLoadingState {
            case .idle:
                tableView.tableFooterView = tableView.dequeueHeaderFooterView(IdleFooterView.self)
            case .loading:
                tableView.tableFooterView = tableView.dequeueHeaderFooterView(LoadingFooterView.self)
            case .retry:
                let view = tableView.dequeueHeaderFooterView(RetryFooterView.self)
                view.onRetry = { [unowned self] in
                    self.loadNextPage()
                }
                tableView.tableFooterView = view
                tableView.scrollRectToVisible(view.frame, animated: true)
            }
        }
    }

    private func loadNextPage() {
        // re-entrancy: if loading already, do not cancel and restart
        guard let nextPageUri = model.next, loadNextPageDataTask == nil else { return }

        pageLoadingState = .loading
        do {
            loadNextPageDataTask = try asyncTransactionList(pageUri: nextPageUri) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            self.pageLoadingState = .idle
                            return
                        }
                        self.onError(GSError.error(description: "Failed to load more transactions", error: error))
                        self.pageLoadingState = .retry
                    }
                case .success(let page):
                    var model = FlatTransactionsListViewModel(page.results)
                    model.next = page.next

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        let transformer = TransactionDataTransformer(safe: self.safe, chain: self.safe.chain!)
                        model.items = transformer.transformed(list: model.items)
                        
                        self.model.append(from: model)
                        self.onSuccess()
                        self.pageLoadingState = .idle
                    }
                }
                self.loadNextPageDataTask = nil
            }
        } catch {
            onError(GSError.error(description: "Failed to load more transactions", error: error))
            pageLoadingState = .retry
        }
    }

    override func onError(_ error: DetailedLocalizedError) {
        App.shared.snackbar.show(error: error)
        if isRefreshing() {
            endRefreshing()
        } else if pageLoadingState == .loading {
            // do nothing here because we want to preserve the visible
            // data when page loading fails
        } else {
            showOnly(view: dataErrorView)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(table: tableView, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLast(path: indexPath) {
            loadNextPage()
        }
    }

    private func isLast(path: IndexPath) -> Bool {
        path.row == model.items.count - 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = model.items[indexPath.row]
        var transaction: SCGModels.TxSummary?
        switch item {
        case .transaction(let tx):
            transaction = tx.transaction
        default:
            transaction = nil
        }

        guard let tx = transaction else { return }
        let vc: TransactionDetailsViewController

        switch tx.txInfo {
        case .creation(let creationInfo):
            let detailsTx = SCGModels.TransactionDetails(
                txId: "",
                safeAddress: AddressString(safe.addressValue),
                txStatus: tx.txStatus,
                txInfo: SCGModels.TxInfo.creation(creationInfo),
                txData: nil,
                detailedExecutionInfo: nil,
                txHash: nil,
                executedAt: tx.timestamp)

            vc = TransactionDetailsViewController(transaction: detailsTx)
        default:
            vc = TransactionDetailsViewController(transactionID: tx.id)
        }
        let ribbon = RibbonViewController(rootViewController: vc)
        show(ribbon, sender: self)

        if tableView.contentOffset == .zero {
            setNeedsReload()
        }
    }

    func cell(table: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let item = model.items[indexPath.row]

        switch item {
        case .conflictHeader(let header):
            let cell = tableView.dequeueCell(TransactionsListConflictHeaderTableViewCell.self, for: indexPath)
            cell.set(nonce: header.nonce.description)
            cell.separatorInset = UIEdgeInsets(top: 0, left: view.frame.size.width, bottom: 0, right: 0)
            cell.selectionStyle = .none
            return cell
        case .dateLabel(let label):
            let cell = tableView.dequeueCell(TransactionListHeaderTableViewCell.self, for: indexPath)
            cell.set(title: dateFormatter.string(from: label.timestamp))
            cell.selectionStyle = .none
            return cell
        case .label(let label):
            let cell = tableView.dequeueCell(TransactionListHeaderTableViewCell.self, for: indexPath)
            cell.set(title: localized(header: label.label))
            return cell
        case .transaction(let transaction):
            let cell = tableView.dequeueCell(TransactionListTableViewCell.self, for: indexPath)
            configure(cell: cell, transaction: transaction)
            return cell
        case .unknown:
            return UITableViewCell()
        }
    }

    func configure(cell: TransactionListTableViewCell, transaction: SCGModels.TransactionSummaryItemTransaction) {
        let tx = transaction.transaction
        var title = ""
        var tag: String = ""
        var image: UIImage?
        var imageURL: URL?
        var placeholderAddress: AddressString?

        let nonce: String
        let confirmationsSubmitted: UInt64
        let confirmationsRequired: UInt64
        let missingSigners: [String]
        
        if let executionInfo = tx.executionInfo,
           case SCGModels.ExecutionInfo.multisig(let multisigExecutionInfo) = executionInfo {
            nonce = multisigExecutionInfo.nonce.description
            confirmationsSubmitted = multisigExecutionInfo.confirmationsSubmitted
            confirmationsRequired = multisigExecutionInfo.confirmationsRequired
            missingSigners = multisigExecutionInfo.missingSigners?.map { $0.value.address.checksummed } ?? []
        } else {
            nonce = ""
            confirmationsSubmitted = 0
            confirmationsRequired = 0
            missingSigners = []
        }

        let date = formatted(date: tx.timestamp)
        var info = ""
        var infoColor: UIColor = .labelPrimary

        var status: SCGModels.TxStatus = tx.txStatus
        if let signingKeyAddresses = try? KeyInfo.all().map({ $0.address.checksummed }), status == .awaitingConfirmations {
            let reminingSigners = missingSigners.filter({ signingKeyAddresses.contains($0) })
            if !reminingSigners.isEmpty {
                status = .awaitingYourConfirmation
            }
        }

        switch tx.txInfo {
        case .transfer(let transferInfo):
            let isOutgoing = transferInfo.direction == .outgoing
            image = isOutgoing ? UIImage(named: "ico-outgoing-tx") : UIImage(named: "ico-incomming-tx")?.withTintColor(.success)
            title = isOutgoing ? "Send" : "Receive"
            info = formattedAmount(transferInfo: transferInfo)
            infoColor = isOutgoing ? .labelPrimary : .baseSuccess
        case .settingsChange(let settingsChangeInfo):
            title = settingsChangeInfo.dataDecoded.method
            image = UIImage(named: "ico-settings-tx")
        case .custom(let customInfo):
            if let safeAppInfo = tx.safeAppInfo {
                title = safeAppInfo.name
                tag = "App"
                imageURL = URL(string: safeAppInfo.logoUri)
                image = UIImage(named: "ico-custom-tx")
                
            } else if let importedSafeName = Safe.cachedName(by: customInfo.to.value, chainId: safe.chain!.id!) {
                title = importedSafeName
                placeholderAddress = customInfo.to.value
            } else {
                title = customInfo.to.name ?? "Contract interaction"
                if let url = customInfo.to.logoUri {
                    imageURL = url
                } else {
                    image = UIImage(named: "ico-custom-tx")
                }
                placeholderAddress = customInfo.to.value
            }
            info = customInfo.actionCount != nil ? "\(customInfo.actionCount!) actions" : customInfo.methodName ?? ""
        case .rejection(_):
            title = "On-chain rejection"
            image = UIImage(named: "ico-rejection-tx")
        case .creation(_):
            image = UIImage(named: "ico-settings-tx")
            title = "Safe Account created"
        case .unknown:
            image = UIImage(named: "ico-custom-tx")
            title = "Unknown operation"
        }

        cell.set(title: title)
        if let imageURL = imageURL, let placeholderAddress = placeholderAddress {
            cell.set(contractImageUrl: imageURL, contractAddress: placeholderAddress)
        } else if let imageURL = imageURL {
            cell.set(imageUrl: imageURL, placeholder: image)
        } else if let image = image {
            cell.set(image: image)
        } else if let placeholderAddress = placeholderAddress {
            cell.set(contractAddress: placeholderAddress)
        }

        cell.set(status: status)
        cell.set(nonce: nonce)
        cell.set(date: date)
        cell.set(info: info, color: infoColor)
        cell.set(conflictType: transaction.conflictType)
        cell.set(tag: tag)
        cell.separatorInset = transaction.conflictType == .hasNext ? UIEdgeInsets(top: 0, left: view.frame.size.width, bottom: 0, right: 0) : UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        cell.set(confirmationsSubmitted: confirmationsSubmitted, confirmationsRequired: confirmationsRequired)
        cell.set(highlight: shouldHighlight(transaction: tx))
    }

    func formattedAmount(transferInfo: SCGModels.TxInfo.Transfer) -> String {
        let isOutgoing = transferInfo.direction == .outgoing

        let sign: Int256 = isOutgoing ? -1 : +1

        var value: Int256
        var decimals: UInt256
        var symbol: String?

        switch transferInfo.transferInfo {
        case .erc20(let erc20TransferInfo):
            value = Int256(erc20TransferInfo.value.value)
            decimals = (try? UInt256(erc20TransferInfo.decimals ?? 0)) ?? 0
            symbol = erc20TransferInfo.tokenSymbol ?? "ERC20"
        case .erc721(let erc721TransferInfo):
            symbol = erc721TransferInfo.tokenSymbol ?? "NFT"
            value = 1
            decimals = 0
        case .nativeCoin(let nativeCoinTransferInfo):
            value = Int256(nativeCoinTransferInfo.value.value)
            let coin = Chain.nativeCoin!
            decimals = UInt256(coin.decimals)
            symbol = coin.symbol
        case .unknown:
            value = 0
            decimals = 0
            symbol = "Unknown"
        }

        let decimalAmount = BigDecimal(value * sign,
                                       Int(clamping: decimals))
        let amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: true
        )

        return [amount, symbol ?? ""].joined(separator: " ")
    }

    func formatted(date: Date) -> String {
        let result = timeFormatter.string(from: date)
        return result
    }

    func shouldHighlight(transaction: SCGModels.TxSummary) -> Bool {
        return false
    }
}
