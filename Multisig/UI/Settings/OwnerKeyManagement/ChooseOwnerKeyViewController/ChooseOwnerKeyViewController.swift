//
//  ChooseOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/10/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import Solidity

protocol AccountBalanceLoader {
    // must call completion handler on the main thread
    // resulting balances list must have the same count as the keys
    //   it is possible to receive empty string - in this case the balance will not be shown
    // the task must not be resumed yet
    func loadBalances(for keys: [KeyInfo], completion: @escaping (Result<[AccountBalanceUIModel], Error>) -> Void) -> URLSessionTask?
}

struct AccountBalanceUIModel {
    var displayAmount: String
    var isEnabled: Bool
    var amount: Sol.UInt256?
}

class ChooseOwnerKeyViewController: UIViewController, PasscodeProtecting {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var headerContentView: UIView!

    private var titleText: String!
    private var owners: [KeyInfo] = []
    private var chainID: String?
    private(set) var selectedKey: KeyInfo? = nil
    private var requestsPassCode: Bool = true
    private var header: Header = .none

    private var balancesLoader: AccountBalanceLoader? = nil
    private var loadingTask: URLSessionTask?
    private var accountBalances: [AccountBalanceUIModel]?
    private var isLoading: Bool = false
    private var pullToRefreshControl: UIRefreshControl!

    var trackingEvent: TrackingEvent = .chooseOwner
    var completionHandler: ((KeyInfo?) -> Void)?

    enum Header {
        case text(description: String)
        case detail(imageUri: URL?, placeholder: UIImage?, title: String, detail: String)
        case none
    }

    var showsCloseButton: Bool = true

    convenience init(
        owners: [KeyInfo],
        chainID: String?,
        titleText: String = "Select owner key",
        header: Header = .none,
        requestsPasscode: Bool = true,
        selectedKey: KeyInfo? = nil,
        // when passed in, then this controller will show account balances.
        balancesLoader: AccountBalanceLoader? = nil,
        completionHandler: ((KeyInfo?) -> Void)? = nil
    ) {
        self.init()
        self.owners = owners
        self.chainID = chainID
        self.titleText = titleText
        self.header = header
        self.requestsPassCode = requestsPasscode
        self.selectedKey = selectedKey
        self.balancesLoader = balancesLoader
        self.completionHandler = completionHandler
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(trackingEvent)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = titleText

        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        }

        tableView.registerCell(ChooseOwnerTableViewCell.self)
        tableView.registerCell(SigningKeyTableViewCell.self)

        configureHeader()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .ownerKeyUpdated,
            object: nil)

        if balancesLoader != nil {
            pullToRefreshControl = UIRefreshControl()
            pullToRefreshControl.addTarget(self,
                    action: #selector(pullToRefreshChanged),
                    for: .valueChanged)
            tableView.refreshControl = pullToRefreshControl
        }

        reloadBalances()
    }

    @objc func reload() {
        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func pullToRefreshChanged() {
        reloadBalances()
    }

    private func configureHeader() {
        switch header {
        case .none:
            headerContentView.heightAnchor.constraint(equalToConstant: 0).isActive = true

        case .text(description: let text):
            let view = ChooseOwnerBasicHeaderView()
            view.textLabel.text = text
            view.translatesAutoresizingMaskIntoConstraints = false
            headerContentView.addSubview(view)
            headerContentView.wrapAroundView(view)

        case let .detail(imageUri: imageUri, placeholder: placeholder, title: title, detail: detail):
            let view = ChooseOwnerDetailHeaderView()
            view.textLabel.text = title
            view.detailTextLabel.text = detail
            view.imageView.setImage(url: imageUri, placeholder: placeholder, failedImage: placeholder)
            view.translatesAutoresizingMaskIntoConstraints = false
            headerContentView.addSubview(view)
            headerContentView.wrapAroundView(view)
        }
    }

    // MARK: - Balances Loading

    func reloadBalances() {
        guard let loader = balancesLoader else { return }
        loadingTask?.cancel()

        self.isLoading = true
        self.tableView.reloadData()

        loadingTask = loader.loadBalances(for: owners, completion: { [weak self] result in
            guard let self = self else { return }

            self.isLoading = false
            self.pullToRefreshControl.endRefreshing()

            switch result {
            case .failure(let error):
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }
                LogService.shared.error("Balances loading failed: \(error)")
                let gsError = GSError.error(description: "Failed to load account balances", error: error)
                App.shared.snackbar.show(error: gsError)

            case .success(let balances):
                // reload data
                self.accountBalances = balances
                self.tableView.reloadData()
            }
        })
    }

    func accountBalance(for keyInfo: KeyInfo) -> AccountBalanceUIModel? {
        if let index = owners.firstIndex(of: keyInfo), let balances = accountBalances, index < balances.count {
            return balances[index]
        }
        return nil
    }
}

extension ChooseOwnerKeyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        owners.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = owners[indexPath.row]
        let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none

        var accessoryImage: UIImage? = UIImage()
        if let selection = selectedKey, keyInfo == selection {
            accessoryImage = UIImage(systemName: "checkmark")?.withTintColor(.primary)
        }

        var accountBalance: String? = nil
        var isEnabled = true
        if let balances = accountBalances, indexPath.row < balances.count {
            let model = balances[indexPath.row]
            accountBalance = model.displayAmount.isEmpty ? nil : model.displayAmount
            isEnabled = model.isEnabled
        }

        cell.configure(keyInfo: keyInfo,
                       chainID: chainID,
                       detail: accountBalance,
                       accessoryImage: accessoryImage,
                       enabled: isEnabled,
                       isLoading: isLoading)

        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let balances = accountBalances, indexPath.row < balances.count, !balances[indexPath.row].isEnabled {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyInfo = owners[indexPath.row]
        selectedKey = keyInfo
        // For WalletConnect key check that it is still connected
        if keyInfo.keyType == .walletConnect {
            switch KeyConnectionStatus.init(keyInfo: keyInfo, chainID: chainID) {
            case .connected:
                completionHandler?(keyInfo)
            case .disconnected, .none:
                connect(keyInfo: keyInfo)
            case .connectionProblem:
                App.shared.snackbar.show(error: GSError.KeyConnectionProblem())
            }
        } else if keyInfo.keyType == .ledgerNanoX || keyInfo.keyType == .keystone {
            completionHandler?(keyInfo)
        } else if requestsPassCode {
            if AppConfiguration.FeatureToggles.securityCenter {
                completionHandler?(keyInfo)
            } else {
                authenticate(options: [.useForConfirmation]) { [weak self] success in
                    self?.completionHandler?(success ? keyInfo : nil)
                }
            }
        } else {
            completionHandler?(keyInfo)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let keyInfo = owners[indexPath.row]
        guard keyInfo.keyType == .walletConnect else {
            return nil            
        }

        let isConnected = keyInfo.connectedAsDapp

        let wcAction = UIContextualAction(style: .normal, title: isConnected ? "Disconnect" : "Connect") {
            [unowned self] _, _, completion in

            if isConnected {
                let alertController = DisconnectionConfirmationController.create(key: keyInfo)
                if let popoverPresentationController = alertController.popoverPresentationController {
                    popoverPresentationController.sourceView = tableView
                    popoverPresentationController.sourceRect = tableView.rectForRow(at: indexPath)
                }

                self.present(alertController, animated: true)
            } else {
                self.connect(keyInfo: keyInfo)
            }

            completion(true)
        }
        wcAction.backgroundColor = isConnected ? .orange : .primary

        return UISwipeActionsConfiguration(actions: [wcAction])
    }

    func connect(keyInfo: KeyInfo) {
        let wcWallet = keyInfo.wallet.flatMap { WCAppRegistryRepository().entry(from: $0) }
        let chain = chainID.flatMap(Chain.by(_:)) ?? Selection.current().safe?.chain ?? Chain.mainnetChain()
        let walletConnectionVC = StartWalletConnectionViewController(wallet: wcWallet, chain: chain, keyInfo: keyInfo)
        let vc = ViewControllerFactory.pageSheet(viewController: walletConnectionVC, halfScreen: wcWallet != nil)
        present(vc, animated: true)
    }

}
