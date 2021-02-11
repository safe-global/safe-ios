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
    private var currentDataTask: URLSessionTask?

    private var results: [TokenBalance] = []

    private var totalBalance: String = "0.00"

    private let tableBackgroundColor: UIColor = .primaryBackground

    enum Section: Int {
        case banner = 0, total, balances
    }

    override var isEmpty: Bool { results.isEmpty }

    @UserDefault(key: "io.gnosis.multisig.importKeyBannerWasShown")
    private var importKeyBannerWasShown: Bool?

    var clientGatewayService = App.shared.clientGatewayService

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BalanceTableViewCell.self)
        tableView.registerCell(TotalBalanceTableViewCell.self)
        tableView.registerCell(ImportKeyBannerTableViewCell.self)

        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor

        tableView.delegate = self
        tableView.dataSource = self

        if importKeyBannerWasShown != true && App.shared.settings.signingKeyAddress != nil {
            importKeyBannerWasShown = true
        }

        emptyView.setText("Balances will appear here")

        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerKeyImported), name: .ownerKeyImported, object: nil)
    }

    @objc private func ownerKeyImported() {
        importKeyBannerWasShown = true
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
                    let results = summary.items.map(TokenBalance.init)
                    let total = TokenBalance.displayCurrency(from: summary.fiatTotal)
                    DispatchQueue.main.async { [weak self] in
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
            return importKeyBannerWasShown != true ? 1 : 0
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
            cell.setSubDetailText(item.balanceUsd)
            if let image = item.image {
                cell.setImage(image)
            } else {
                cell.setImage(with: item.imageURL, placeholder: #imageLiteral(resourceName: "ico-token-placeholder"))
            }
            return cell
        case .banner:
            let cell = tableView.dequeueCell(ImportKeyBannerTableViewCell.self, for: indexPath)
            cell.onClose = { [unowned self] in
                importKeyBannerWasShown = true
                updateSection(indexPath.section)
            }
            cell.onImport = { [unowned self] in
                importKeyBannerWasShown = true
                updateSection(indexPath.section)
                let vc = ViewControllerFactory.importOwnerViewController(presenter: self)
                present(vc, animated: true)
            }
            return cell
        }
    }

    private func updateSection(_ section: Int) {
        tableView.beginUpdates()
        tableView.reloadSections([section], with: .automatic)
        tableView.endUpdates()
    }
}
