//
//  SelectNetworkViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/24/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectNetworkViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
                        self.onError(GSError.error(description: "Failed to load networks", error: error))
                    }
                case .success(let summary):
                    DispatchQueue.main.async { [weak self] in
                        let results = summary.items.map { TokenBalance($0, code: AppSettings.selectedFiatCode) }
                        let total = TokenBalance.displayCurrency(from: summary.fiatTotal, code: AppSettings.selectedFiatCode)
                        guard let `self` = self else { return }
                        self.sections = self.makeSections(items: results, total: total)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load networks", error: error))
        }
    }

}
