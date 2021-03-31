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
    var clientGatewayService = App.shared.clientGatewayService

    override var isEmpty: Bool { results.isEmpty }

    private var currentDataTask: URLSessionTask?

    private var results: [TokenBalance] = []

    private var totalBalance: String = "0.00"

    private let tableBackgroundColor: UIColor = .primaryBackground

    @UserDefault(key: "io.gnosis.multisig.importKeyBannerWasShown")
    private var importKeyBannerWasShown: Bool?

    private var shouldShowBanner: Bool {
        shouldShowImportKeyBanner || shouldShowPasscodeBanner
    }

    private var shouldShowImportKeyBanner: Bool {
        importKeyBannerWasShown != true
    }

    private var shouldShowPasscodeBanner: Bool {
        PrivateKeyController.hasPrivateKey &&
            !(AppSettings.passcodeBannerDismissed || AppSettings.passcodeWasSetAtLeastOnce)
    }

    enum Section: Int {
        case banner = 0, total, balances
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BalanceTableViewCell.self)
        tableView.registerCell(TotalBalanceTableViewCell.self)
        tableView.registerCell(BannerTableViewCell.self)

        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor

        tableView.delegate = self
        tableView.dataSource = self

        if importKeyBannerWasShown != true && PrivateKeyController.hasPrivateKey {
            importKeyBannerWasShown = true
        }

        emptyView.setText("Balances will appear here")

        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerKeyImported), name: .ownerKeyImported, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(updatePasscodeBanner), name: .passcodeCreated, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(lazyReloadData), name: .selectedFiatCurrencyChanged, object: nil)

    }

    @objc private func ownerKeyImported() {
        importKeyBannerWasShown = true
        tableView.reloadData()
    }

    @objc private func updatePasscodeBanner() {
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.assetsCoins)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            let safe = try Safe.getSelected()!
            let address = try Address(from: safe.address!)

            currentDataTask = clientGatewayService.asyncBalances(address: address) { [weak self] result in
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
                        self.results = results
                        self.totalBalance = total
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load balances", error: error))
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .balances:
            return results.count
        case .total:
            return 1
        case .banner:
            return shouldShowBanner ? 1 : 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .total:
            let cell = tableView.dequeueCell(TotalBalanceTableViewCell.self, for: indexPath)
            cell.setMainText("Total")
            cell.setDetailText(totalBalance)
            return cell
        case .balances:
            let item = results[indexPath.row]
            let cell = tableView.dequeueCell(BalanceTableViewCell.self, for: indexPath)
            cell.setMainText(item.symbol)
            cell.setDetailText(item.balance)
            cell.setSubDetailText(item.fiatBalance)
            if let image = item.image {
                cell.setImage(image)
            } else {
                cell.setImage(with: item.imageURL, placeholder: #imageLiteral(resourceName: "ico-token-placeholder"))
            }
            return cell
        case .banner:
            if shouldShowImportKeyBanner {
                return importKeyBanner(indexPath: indexPath)
            } else if shouldShowPasscodeBanner {
                return createPasscodeBanner(indexPath: indexPath)
            } else {
                preconditionFailure("Programmer error: check the cell count")
            }
        }
    }

    private func importKeyBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader("Import owner key")
        cell.setBody("We added signing support to the app! Now you can import your owner key and sign transactions on the go.")
        cell.setButton("Import owner key now")
        cell.onClose = { [unowned self] in
            importKeyBannerWasShown = true
            updateSection(indexPath.section)
            trackEvent(.bannerImportOwnerKeySkipped)
        }
        cell.onImport = { [unowned self] in
            importKeyBannerWasShown = true
            updateSection(indexPath.section)
            let vc = ViewControllerFactory.importOwnerViewController(presenter: self)
            present(vc, animated: true)
            trackEvent(.bannerImportOwnerKeyImported)
        }
        return cell
    }

    private func createPasscodeBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader("Create passcode")
        cell.setBody("Secure your owner keys by setting up a passcode. The passcode will be needed to open the app and sign transactions.")
        cell.setButton("Create passcode now")
        cell.onClose = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            updateSection(indexPath.section)
        }
        cell.onImport = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            updateSection(indexPath.section)
            let vc = CreatePasscodeViewController { [weak self] in
                self?.updateSection(indexPath.section)
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
        return cell
    }

    private func updateSection(_ section: Int) {
        tableView.beginUpdates()
        tableView.reloadSections([section], with: .automatic)
        tableView.endUpdates()
    }
}
