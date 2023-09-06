//
//  AddOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit


class AddOwnerKeyViewController: UITableViewController {
    private typealias SectionItems = (section: String, items: [Row])

    private var sections = [SectionItems]()

    var importKeyFlow: ImportKeyFlow!
    var generateKeyFlow: GenerateKeyFlow!
    var connectKeystoneFlow: ConnectKeystoneFlow!
    var walletConnectKeyFlow: WalletConnectKeyFlow!
    var ledgerKeyFlow: LedgerKeyFlow!
    var socialKeyFlow: AddSocialKeyFlow!

    enum Row {
        case social
        case generate
        case importKey
        case ledger
        case keystone
        case walletConnect

        var title: String {
            switch self {
            case .social:
                return "Create or import with Google or Apple ID"
            case .generate:
                return "Create new owner key"
            case .importKey:
                return "Import existing key"
            case .ledger:
                return "Connect Ledger Nano X"
            case .keystone:
                return "Connect Keystone"
            case .walletConnect:
                return "Connect a key"
            }
        }

        var image: UIImage {
            switch self {
            case .generate:
                return UIImage(named: KeyType.deviceGenerated.imageName)!
            case .importKey:
                return UIImage(named: KeyType.deviceImported.imageName)!
            case .walletConnect:
                return UIImage(named: KeyType.walletConnect.imageName)!
            case .keystone:
                return UIImage(named: KeyType.keystone.imageName)!
            case .ledger:
                return UIImage(named: KeyType.ledgerNanoX.imageName)!
            case .social:
                return UIImage(named: "ico-add")!
            }
        }

        var style: AddOwnerKeyCell.Style {
            switch self {
            case .social:
                return .highlighted
            default:
                return .normal
            }
        }

        var detailsImage: UIImage? {
            switch self {
            case .walletConnect:
                return UIImage(named: "ico-wallet-logos")
            default:
                return nil
            }
        }
    }

    private(set) var completion: () -> Void = {}
    private var showsCloseButton: Bool = true

    convenience init(showsCloseButton: Bool = true, completion: @escaping () -> Void) {
        self.init()
        self.completion = completion
        self.showsCloseButton = showsCloseButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Owner Key"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(CloseModal.closeModal))
        }

        tableView.registerCell(AddOwnerKeyCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .backgroundSecondary
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        sections = [
            (section: "Start from scratch", items: [.social, .generate]),
            (section: "Already have a key?", items: [.walletConnect, .importKey]),
            (section: "Connect a hardware wallet", items: [.ledger, .keystone])
        ]

        let header = TableHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        header.set("Use owner keys independently or as Safe owners to login, confirm and transact.", backgroundColor: .clear)

        tableView.tableHeaderView = header
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerKeysOptions)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(sections[section].section, backgroundColor: .clear)

        return view
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(AddOwnerKeyCell.self)
        let option = sections[indexPath.section].items[indexPath.row]

        cell.set(title: option.title)
        cell.set(image: option.image)
        cell.set(style: option.style)
        cell.set(detailsImage: option.detailsImage)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].items[indexPath.row] {
        case .importKey:
            importKeyFlow = ImportKeyFlow { [weak self] _ in
                self?.importKeyFlow = nil
                self?.completion()
            }
            push(flow: importKeyFlow)
            return

        case .generate:
            generateKeyFlow = GenerateKeyFlow { [weak self] _ in
                self?.generateKeyFlow = nil
                self?.completion()
            }
            push(flow: generateKeyFlow)
            return

        case .walletConnect:
            walletConnectKeyFlow = WalletConnectKeyFlow { [weak self] _ in
                self?.walletConnectKeyFlow = nil
                self?.completion()
            }
            push(flow: walletConnectKeyFlow)
            return

        case .ledger:
            ledgerKeyFlow = LedgerKeyFlow { [weak self] _ in
                self?.ledgerKeyFlow = nil
                self?.completion()
            }
            push(flow: ledgerKeyFlow)
            return
            
        case .keystone:
            connectKeystoneFlow = ConnectKeystoneFlow { [weak self] _ in
                self?.connectKeystoneFlow = nil
                self?.completion()
            }
            push(flow: connectKeystoneFlow)
            return
        case .social:
            socialKeyFlow = AddSocialKeyFlow { [weak self] _ in
                self?.socialKeyFlow = nil
                self?.completion()
            }
            push(flow: socialKeyFlow)
            return
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        BasicHeaderView.headerHeight
    }
}
