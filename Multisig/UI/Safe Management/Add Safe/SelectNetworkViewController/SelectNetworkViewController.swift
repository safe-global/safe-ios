//
//  SelectNetworkViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/24/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectNetworkViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService
    private var currentDataTask: URLSessionTask?
    private let tableBackgroundColor: UIColor = .primaryBackground

    var completion: () -> Void = { }
    private var chains: [SCGModels.Chain] = []

    override var isEmpty: Bool {
        chains.isEmpty
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(SelectNetworkTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor
        tableView.delegate = self
        tableView.dataSource = self

        navigationItem.title = "Load Gnosis Safe"
        emptyView.setText("Networks will appear here")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.assetsCoins)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        currentDataTask = clientGatewayService.chains(completion: { [weak self] result in
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
                    self.onError(GSError.error(description: "Failed to load networks", error: error))
                }
            case .success(let chains):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.chains = chains
                    self.onSuccess()
                }
            }
        })
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableHeaderView = TableHeaderView()
        tableHeaderView.set("Select network on which your Safe was created:")
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        100
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chains.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(SelectNetworkTableViewCell.self, for: indexPath)
        let chain = chains[indexPath.row]

        cell.nameLabel.text = chain.chainName
        cell.colorImageView.tintColor = UIColor(hex: chain.theme.backgroundColor.description)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = EnterSafeAddressViewController()
        vc.completion = completion
        vc.network = chains[indexPath.row]
        show(vc, sender: self)
    }
}
