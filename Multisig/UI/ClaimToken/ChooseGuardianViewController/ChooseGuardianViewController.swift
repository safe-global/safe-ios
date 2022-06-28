//
//  ChooseGuardianViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseGuardianViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    var guardians: [Guardian] = []
    var onSelect: ((Guardian) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(GuardianTableViewCell.self)
    }
}

extension ChooseGuardianViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guardians.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(GuardianTableViewCell.self)
        cell.set(guardian: guardians[indexPath.row])
        cell.onSelect = { [unowned self] in
            onSelect?(guardians[indexPath.row])
        }

        return cell
    }
}


struct Guardian {
    let name: String?
    let imageURL: String?
    let ensName: String?
    let address: Address
    let message: String?
}
