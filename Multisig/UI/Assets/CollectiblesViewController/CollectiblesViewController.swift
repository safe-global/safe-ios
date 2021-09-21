//
//  CollectiblesViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

protocol JPEGsViewControllerDelegate: AnyObject {
    func jpegsViewControllerDidFinishLoading(_ controller: CollectiblesViewController)
}

class CollectiblesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var clientGatewayService = App.shared.clientGatewayService
    let rowHeight: CGFloat = 160
    let headerHeight: CGFloat = 52
    let footerHeight: CGFloat = 13
    let tableBackgroundColor: UIColor = .primaryBackground

    var currentDataTask: URLSessionTask?
    var sections = [CollectibleListSection]()

    weak var delegate: JPEGsViewControllerDelegate?

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
        tableView.registerHeaderFooterView(CollecitbleSectionSeparatorView.self)
        tableView.rowHeight = rowHeight
        tableView.sectionHeaderHeight = headerHeight
        tableView.sectionFooterHeight = footerHeight
        tableView.separatorStyle = .none

        emptyView.setText("JPEGs will appear here")
        emptyView.setImage(UIImage(named: "ico-no-collectibles")!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsCollectibles)
    }

    override func reloadData() {
        super.reloadData()

        currentDataTask?.cancel()

        let safe = try! Safe.getSelected()!

        currentDataTask = clientGatewayService.asyncCollectibles(safeAddress: safe.addressValue, chainId: safe.chain!.id!) { [weak self] result in
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
                    self.onError(GSError.error(description: "Failed to load JPEGs", error: error))
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
    }

    override func onError(_ error: DetailedLocalizedError) {
        super.onError(error)
        delegate?.jpegsViewControllerDidFinishLoading(self)
    }

    override func onSuccess() {
        super.onSuccess()
        delegate?.jpegsViewControllerDidFinishLoading(self)
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
        cell.setImage(with: collectible.imageURL, placeholder: UIImage(named: "ico-collectible-placeholder")!)
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let collectible = sections[indexPath.section].collectibles[indexPath.row]
        let root = CollectibleDetailViewController(nibName: nil, bundle: nil)
        root.collectible = collectible
        let vc = RibbonViewController(rootViewController: root)
        show(vc, sender: self)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(CollectiblesHeaderView.self)
        let collectibleSection = sections[section]
        view.setName(collectibleSection.name)
        view.setImage(with: collectibleSection.imageURL, placeholder: UIImage(named: "ico-jpeg-placeholder")!)
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        tableView.dequeueHeaderFooterView(CollecitbleSectionSeparatorView.self)
    }

}
