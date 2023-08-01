//
//  SelectTopUpAddressViewController.swift
//  Multisig
//
//  Created by Mouaz on 7/30/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class SelectTopUpAddressViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var onSelect: (String) -> () = {String in }
    private var currentDataTask: URLSessionTask?
    var safe: Safe!

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()
    
    enum Section {
        case safeAccount(String)
        case owners(String)

        enum SafeAccount: SectionItem {
            case safe
        }

        enum Owner: SectionItem {
            case owner(AddressInfo)
        }
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .backgroundSecondary
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(SafeEntryTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        tableView.delegate = self
        tableView.dataSource = self
        title = "Buy crypto"

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.screenSelectTopUpAddress)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        currentDataTask = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                        chainId: safe.chain!.id!) { [weak self] result in
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
                    self.onError(GSError.error(description: "Failed to load safe info", error: error))
                }
            case .success(let info):
                DispatchQueue.main.async { [weak self] in
                    self?.safe.update(from: info)
                    self?.buildSections()
                    self?.onSuccess()
                }
            }
        }
    }

    private func buildSections() {
        sections = []

        sections.append(SectionItems(section: .safeAccount("SAFE ACCOUNT"), items: [Section.SafeAccount.safe]))
        sections.append(SectionItems(section: .owners("ACCOUNT OWNER KEYS"),
                                     items: safe.ownersInfo!.map { Section.Owner.owner($0) }))
        let view = TableHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        view.set("Choose for which account or owner key you would like to top up", centered: true)
        tableView.tableHeaderView = view
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].section {
        case .safeAccount(_):
            let cell = tableView.dequeueCell(SafeEntryTableViewCell.self, for: indexPath)
            cell.setName(safe.displayName)
            cell.setProgress(enabled: false)
            cell.setAddress(safe.addressValue)
            cell.setDetail(address: safe.addressValue, prefix: safe.chain!.shortName)
            cell.setSelection(false)
            cell.selectionStyle = .none

            return cell
        case .owners(_):
            if case let Section.Owner.owner(info) = sections[indexPath.section].items[indexPath.row] {
                let keyInfo = try? KeyInfo.keys(addresses: [info.address]).first
                let (name, _) = NamingPolicy.name(for: info.address,
                                                            info: info,
                                                            chainId: safe.chain!.id!)
                return addressDetailsCell(address: info.address,
                                          name: keyInfo?.displayName ?? name,
                                          indexPath: indexPath,
                                          badgeName: keyInfo?.keyType.badgeName,
                                          prefix: safe.chain!.shortName)
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].section {
        case .safeAccount(_):
            Tracker.trackEvent(.userTopUpSafeAccount)
            onSelect(safe.address!)
        case .owners(_):
            if case let Section.Owner.owner(info) = sections[indexPath.section].items[indexPath.row] {
                Tracker.trackEvent(.userTopUpEOA)
                onSelect(info.address.checksummed)
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view: UIView?

        var title: String = ""
        switch sections[section].section {
        case .safeAccount(let name):
            title = name
        case .owners(let name):
            title = name
        }

        view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        (view as! BasicHeaderView).setName(title, backgroundColor: .clear, style: .caption2Secondary)

        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        DetailAccountCell.headerHeight
    }

    private func addressDetailsCell(address: Address,
                                    name: String?,
                                    indexPath: IndexPath,
                                    badgeName: String? = nil,
                                    prefix: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: name, badgeName: badgeName, copyEnabled: false, prefix: prefix)

        return cell
    }
}
