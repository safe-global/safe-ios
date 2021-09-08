//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PairedBrowsersViewController: UITableViewController {    

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Paired Browsers"

        tableView.backgroundColor = .primaryBackground
        tableView.registerHeaderFooterView(PairedBrowsersHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
    }

    func scan() {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { value in
            guard value.starts(with: "wc:") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(PairedBrowsersHeaderView.self)
        view.onScan = { [unowned self] in
            self.scan()
        }
        return view
    }
}

extension PairedBrowsersViewController: QRCodeScannerViewControllerDelegate {
    #warning("TODO: add tracking")
    func scannerViewControllerDidScan(_ code: String) {
        do {
            try WalletConnectKeysServerController.shared.connect(url: code)
            dismiss(animated: true, completion: nil)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
}
