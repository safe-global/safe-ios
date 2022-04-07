//
//  CellTestViewController.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 09.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
@testable import Multisig

class CellTestViewController<CellType: UITableViewCell>: UITableViewController {
    var rowHeight: CGFloat = UITableView.automaticDimension
    var estimatedRowHeight: CGFloat = 44
    var background: UIColor = .backgroundPrimary
    var configure: CellConfigureClosure = { _ in }

    typealias CellConfigureClosure = (_ cell: CellType) -> Void

    convenience init(
        rowHeight: CGFloat = UITableView.automaticDimension,
        estimatedHeight: CGFloat = 44,
        background: UIColor = .backgroundPrimary,
        configure: @escaping CellConfigureClosure = {_ in }
    ) {
        self.init()
        self.rowHeight = rowHeight
        self.estimatedRowHeight = estimatedHeight
        self.background = background
        self.configure = configure
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(CellType.self)
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.backgroundColor = background
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CellType.self, for: indexPath)
        configure(cell)
        return cell
    }
}
