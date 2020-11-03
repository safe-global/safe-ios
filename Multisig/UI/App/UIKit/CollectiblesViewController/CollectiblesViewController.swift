//
//  CollectiblesViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectiblesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    let clientGatewayService = App.shared.clientGatewayService
    let rowHeight: CGFloat = 160
    let headerHeight: CGFloat = 52
    let footerHeight: CGFloat = 2
    let tableBackgroundColor: UIColor = .gnoWhite

    var currentDataTask: URLSessionTask?
    var sections = [CollectibleListSection]()
    var lastError: Error?

    override var isEmpty: Bool { sections.isEmpty }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(CollectibleTableViewCell.self)
        tableView.registerHeaderFooterView(CollectiblesHeaderView.self)
        tableView.rowHeight = rowHeight
        tableView.sectionHeaderHeight = headerHeight
        tableView.sectionFooterHeight = footerHeight
        tableView.backgroundColor = tableBackgroundColor
        tableView.separatorStyle = .none

        emptyView.setText("Collectibles will appear here")
        emptyView.setImage(#imageLiteral(resourceName: "ico-no-collectibles"))
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            let address = try Address(from: try Safe.getSelected()!.address!)

            currentDataTask = clientGatewayService.asyncCollectibles(at: address) { [weak self] result in
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
                        self.lastError = error
                        self.onError()
                    }
                case .success(let collectibles):
                    let sections = CollectibleListSection.create(collectibles)

                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.sections = sections
                        self.onSuccess()
                    }
                }
            }
        } catch {
            lastError = error
            onError()
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].collectibles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(CollectibleTableViewCell.self, for: indexPath)
        let collectible = sections[indexPath.section].collectibles[indexPath.row]
        cell.setName(collectible.name)
        cell.setDescription(collectible.description)
        cell.setImage(with: collectible.imageURL, placeholder: #imageLiteral(resourceName: "ico-collectible-placeholder"))
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(CollectiblesHeaderView.self)
        view.configure(collectibleSection: sections[section])
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: footerHeight))
        view.backgroundColor = .gnoWhite
        return view
    }
}
