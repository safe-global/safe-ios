//
//  SelectFiatViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/17/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectFiatViewController: LoadableViewController {
    var currencies: [String] = []

    private var currentDataTask: URLSessionTask?

    convenience init() {
        self.init(namedClass: Self.superclass())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Fiat Currency"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(BasicCell.self)
        tableView.rowHeight = BasicCell.rowHeight

        tableView.backgroundColor = .secondaryBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsSelectFiat)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        currentDataTask = App.shared.clientGatewayService.fiatCurrencies() { [weak self] result in
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

                    self.onError(GSError.error(description: "Failed to load fiats", error: error))
                }
            case .success(let results):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.currencies = results
                    self.onSuccess()
                }
            }
        }
    }
}

extension SelectFiatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        let code = currencies[indexPath.row]

        cell.setTitle(NSLocale.getCurrencyFullName(code: code))
        cell.setDisclosureImage(currencies[indexPath.row] == AppSettings.selectedFiatCode ? UIImage(systemName: "checkmark")?.withTintColor(.button) : nil)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppSettings.selectedFiatCode = currencies[indexPath.row]
        NotificationCenter.default.post(name: .selectedFiatCurrencyChanged, object: nil)
        tableView.reloadData()
    }
}

extension NSLocale {
    static func getCurrencyFullName(code: String) -> String {
        [code, Locale.current.localizedString(forCurrencyCode: code) ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }
}

