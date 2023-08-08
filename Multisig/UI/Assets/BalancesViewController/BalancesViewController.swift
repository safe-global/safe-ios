//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

// Loads and displays balances
class BalancesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    private enum Section {
        case importKeyBanner
        case passcodeBanner
        case balances(items: [TokenBalance])
    }
    var clientGatewayService: BalancesAPI = App.shared.clientGatewayService
    var remoteConfig: FirebaseRemoteConfig = FirebaseRemoteConfig.shared
    var createPasscodeFlow: CreatePasscodeFlow!

    override var isEmpty: Bool {
        var result = false
        if sections.isEmpty {
            result = true
        } else if sections.count == 1 {
            if let firstItem = sections.first {
                switch firstItem {
                case .balances(let items):
                    result = isEmptyAccount(items: items)
                default:
                    break
                }
            }
        }
        return result
    }

    private var currentDataTask: URLSessionTask?

    private var sections: [Section] = []

    private let tableBackgroundColor: UIColor = .backgroundPrimary

    private var shouldShowImportKeyBanner: Bool {
        importKeyBannerWasShown != true && !shouldShowSafeTokenBanner
    }

    private var importKeyBannerWasShown: Bool? {
        get { AppSettings.importKeyBannerWasShown }
        set { AppSettings.importKeyBannerWasShown = newValue }
    }

    private var shouldShowPasscodeBanner: Bool {
        OwnerKeyController.hasPrivateKey && AppSettings.shouldOfferToSetupPasscode && !shouldShowSafeTokenBanner
    }

    private var shouldShowSafeTokenBanner: Bool {
        guard let safe = try? Safe.getSelected() else {
            return false
        }
        return safeTokenBannerWasShown != true && ClaimingAppController.isAvailable(chain: safe.chain!)
    }

    private var safeTokenBannerWasShown: Bool? {
        get { AppSettings.safeTokenBannerWasShown }
        set { AppSettings.safeTokenBannerWasShown = newValue }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BalanceTableViewCell.self)
        tableView.registerCell(BannerTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor

        tableView.delegate = self
        tableView.dataSource = self

        if importKeyBannerWasShown != true && OwnerKeyController.hasPrivateKey {
            importKeyBannerWasShown = true
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerKeyImported), name: .ownerKeyImported, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(updatePasscodeBanner), name: .passcodeCreated, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(lazyReloadData), name: .selectedFiatCurrencyChanged, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(lazyReloadData), name: .chainInfoChanged, object: nil)

        recreateSectionsWithCurrentItems()
    }

    @objc private func ownerKeyImported() {
        importKeyBannerWasShown = true
        recreateSectionsWithCurrentItems()
    }

    @objc private func updatePasscodeBanner() {
        recreateSectionsWithCurrentItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsCoins)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            if let safe = try? Safe.getSelected(), safe.chain?.isSupported(feature: .moonpay) ?? false {
                emptyView.setTitle("Add some crypto to get started")
                emptyView.setDescription("Buy crypto directly with your credit card or a bank account")
                emptyView.setAction(text: "Buy crypto", action: { [weak self] in
                    guard let safe = try? Safe.getSelected() else {
                        return
                    }

                    Tracker.trackEvent(.userBuyCrypto)
                    let vc = ViewControllerFactory.selectTopUpAddress(safe: safe)

                    self?.present(vc, animated: true)
                })
            } else {
                emptyView.setTitle("Balances will appear here")
                emptyView.setDescription(nil)
                emptyView.setAction(text: nil) { }
            }
            guard let safe = try Safe.getSelected() else {
                return
            }
            NotificationCenter.default.post(
                name: .balanceLoading,
                object: self
            )
            currentDataTask = clientGatewayService.asyncBalances(safeAddress: safe.addressValue,
                                                                 chainId: safe.chain!.id!) { [weak self] result in
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
                        self.onError(GSError.error(description: "Failed to load balances", error: error))
                    }
                case .success(let summary):
                    DispatchQueue.main.async { [weak self] in
                        let results = summary.items.map { TokenBalance($0, code: AppSettings.selectedFiatCode) }
                        let total = TokenBalance.displayCurrency(from: summary.fiatTotal, code: AppSettings.selectedFiatCode)
                        guard let `self` = self else { return }
                        
                        //update coins total balance header by propagating total value and balances
                        //propagation of balances is needed to init SelectAssetViewController from AssetsViewController when send button is clicked
                        NotificationCenter.default.post(
                            name: .balanceUpdated,
                            object: self,
                            userInfo: ["balances": results, "total": total]
                        )
                        self.sections = self.makeSections(items: results)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load balances", error: error))
        }
    }
    
    private func makeSections(items: [TokenBalance]) -> [Section] {
        guard !isEmptyAccount(items: items) else { return [] }

        var sections = [Section]()

        if shouldShowImportKeyBanner {
            sections.append(.importKeyBanner)
        } else if shouldShowPasscodeBanner {
            sections.append(.passcodeBanner)
        }

        sections.append(.balances(items: items))
        return sections
    }
    
    private func isEmptyAccount(items: [TokenBalance]) -> Bool {
        items.isEmpty || items.count == 1 && items.first?.balance == "0"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .importKeyBanner, .passcodeBanner: return 1
        case .balances(items: let items): return items.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .importKeyBanner:
            return importKeyBanner(indexPath: indexPath)
        case .passcodeBanner:
            return createPasscodeBanner(indexPath: indexPath)
        case .balances(items: let items):
            let item = items[indexPath.row]
            let cell = tableView.dequeueCell(BalanceTableViewCell.self, for: indexPath)
            cell.setMainText(item.symbol)
            cell.setDetailText(item.balance)
            cell.setSubDetailText(item.fiatBalance)
            cell.setBrowsingEnabled(item.address != TokenBalance.nativeTokenAddress)
            if let image = item.image {
                cell.setImage(image)
            } else {
                cell.setImage(with: item.imageURL, placeholder: UIImage(named: "ico-token-placeholder")!)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .balances(items: let items):
            do {
                let item = items[indexPath.row]
                guard let safe = try Safe.getSelected(), item.address != TokenBalance.nativeTokenAddress else { return }
                openInSafari(safe.chain!.browserURL(address: item.address))
            } catch {
                App.shared.snackbar.show(
                    error: GSError.error(description: "Failed to update selected safe", error: error))
            }
        default: break
        }
    }

    private func showSend(balance: TokenBalance) {
        Tracker.trackEvent(.assetsTransferSelectedAsset)
        let transferFundsVC = TransactionViewController()
        transferFundsVC.tokenBalance = balance
        let ribbon = ViewControllerFactory.ribbonWith(viewController: transferFundsVC)
        present(ViewControllerFactory.modal(viewController: ribbon), animated: true)
    }

    private func importKeyBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader(ImportKeyBanner.Strings.header)
        cell.setBody(ImportKeyBanner.Strings.body)
        cell.setButton(ImportKeyBanner.Strings.button)
        cell.onClose = { [unowned self] in
            importKeyBannerWasShown = true

            recreateSectionsWithCurrentItems()

            Tracker.trackEvent(.bannerImportOwnerKeySkipped)
        }
        cell.onImport = { [unowned self] in
            importKeyBannerWasShown = true

            recreateSectionsWithCurrentItems()

            let vc = ViewControllerFactory.addOwnerViewController {
                self.dismiss(animated: true, completion: nil)
            }
            present(vc, animated: true)
            Tracker.trackEvent(.bannerImportOwnerKeyAdd)
        }
        cell.selectionStyle = .none
        return cell
    }

    private func createPasscodeBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader(PasscodeBanner.Strings.header)
        cell.setBody(PasscodeBanner.Strings.body)
        cell.setButton(PasscodeBanner.Strings.button)
        cell.onClose = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            recreateSectionsWithCurrentItems()
            Tracker.trackEvent(.skipPasscodeBanner)
        }
        cell.onImport = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            recreateSectionsWithCurrentItems()

            createPasscodeFlow = CreatePasscodeFlow(completion: { [unowned self] _ in
                createPasscodeFlow = nil
                recreateSectionsWithCurrentItems()
            })
            present(flow: createPasscodeFlow)

            Tracker.trackEvent(.setupPasscodeFromBanner)
        }
        cell.selectionStyle = .none
        return cell
    }

    private func recreateSectionsWithCurrentItems() {
        var items = [TokenBalance]()
        for section in sections {
            switch section {
            case .balances(items: let balances): items = balances
            default: continue
            }
        }
        sections = makeSections(items: items)
        tableView.reloadData()
    }
}

extension BalancesViewController {
    enum ImportKeyBanner {
        enum Strings {
            static let header = "Add owner key"
            static let body = "Did you know that you can import your owner key to sign and execute transactions on the go?"
            static let button = "Add owner key now"
        }
    }

    enum PasscodeBanner {
        enum Strings {
            static let header = "Create passcode"
            static let body = "Secure your owner keys by setting up a passcode. The passcode will be needed to open the app and sign transactions."
            static let button = "Create passcode now"
        }
    }
}
