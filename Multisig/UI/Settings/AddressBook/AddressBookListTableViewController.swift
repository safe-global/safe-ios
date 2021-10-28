//
//  AddressbookListTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

class AddressBookListTableViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    private var chainEntities: Chain.ChainEntities = []
    private var addButton: UIBarButtonItem!
    override var isEmpty: Bool {
        chainEntities.isEmpty
    }

    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Address Book"

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .primaryBackground

        tableView.registerCell(DetailAccountCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setText("There are no address book entities")
        emptyView.setImage(UIImage(named: "ico-no-address-book")!)

        addButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showOptionsMenu))
        navigationItem.rightBarButtonItem = addButton

        for notification in [Notification.Name.selectedSafeChanged, .addressbookChanged] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(reloadData), name: notification, object: nil)
        }

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addressbookList)
    }

    @objc private func showOptionsMenu() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        let addEnityButton = UIAlertAction(title: "Add new entity", style: .default) { _ in
            self.didTapAddButton()
        }

        alertController.addAction(addEnityButton)

        let importEntityButton = UIAlertAction(title: "Import entities", style: .default) { [unowned self] _ in
            let pricker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeCommaSeparatedText)], in: .import)
            pricker.delegate = self
            pricker.allowsMultipleSelection = false
            self.present(pricker, animated: true, completion: nil)
        }

        alertController.addAction(importEntityButton)

        if let csv = AddressBookEntity.exportToCSV() {
            let exportEntityButton = UIAlertAction(title: "Export entities", style: .default) { [unowned self] _ in
                if let exportedFileURL = FileManagerWrapper.export(text: csv,
                                                                   fileName: "AddressBook",
                                                                   fileExtension: String(kUTTypeCommaSeparatedText)) {
                    let activityViewController : UIActivityViewController = UIActivityViewController(
                        activityItems: [exportedFileURL], applicationActivities: nil)

                    self.present(activityViewController, animated: true, completion: nil)
                }
            }

            alertController.addAction(exportEntityButton)
        }

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelButton)

        self.present(alertController, animated: true)
    }

    private func didTapAddButton() {
        let vc = CreateAddressBookEntityViewController()
        vc.completion = { [unowned self, unowned notificationCenter] (address, name)  in
            guard let chain = Chain.by(chainId) else { return }
            AddressBookEntity.create(address: address.checksummed, name: name, chain: chain)
            notificationCenter.post(name: .addressbookChanged, object: self, userInfo: nil)
            navigationController?.popViewController(animated: true)
            self.reloadData()
        }

        let ribbonVC = RibbonViewController(rootViewController: vc)
        show(ribbonVC, sender: self)
    }
    
    @objc override func reloadData() {
        chainEntities = Chain.chainEntities()
        tableView.reloadData()
        onSuccess()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        chainEntities.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chainEntities[section].entities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        let entity = chainEntities[indexPath.section].entities[indexPath.row]

        cell.setAccount(address: entity.addressValue, label: entity.name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEdit(entity: chainEntities[indexPath.section].entities[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entity = chainEntities[indexPath.section].entities[indexPath.row]

        var actions = [UIContextualAction]()
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, completion in
            showEdit(entity: chainEntities[indexPath.section].entities[indexPath.row])
            completion(true)
        }
        actions.append(editAction)

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, completion in
            self.remove(entity)
            completion(true)
        }
        actions.append(deleteAction)

        return UISwipeActionsConfiguration(actions: actions)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(NetworkIndicatorHeaderView.self)
        let chain = chainEntities[section].chain
        view.text = chain.name
        view.dotColor = chain.backgroundColor
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        NetworkIndicatorHeaderView.height
    }

    private func showEdit(entity: AddressBookEntity) {
        let defaultName = entity.name

        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Save"
        enterNameVC.descriptionText = "Choose a name for the entity. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter entity Name"
        enterNameVC.trackingEvent = .addressbookEditEntity
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = defaultName
        enterNameVC.address = entity.addressValue
        enterNameVC.completion = { [unowned self, unowned entity, unowned notificationCenter] name in
            AddressBookEntity.update(entity.displayAddress, chainId: entity.chain!.id!, name: name)
            notificationCenter.post(name: .addressbookChanged, object: self, userInfo: nil)
            navigationController?.popViewController(animated: true)
        }
        
        let ribbonVC = RibbonViewController(rootViewController: enterNameVC)

        show(ribbonVC, sender: nil)
    }

    private func remove(_ entity: AddressBookEntity) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the entity key only removes it from this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            AddressBookEntity.remove(entity: entity)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension AddressBookListTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if let csv = FileManagerWrapper.importFile(url: url) {
            let result = AddressBookEntity.importFrom(csv: csv)
            App.shared.snackbar.show(message: "\(result.0) entities imported. \(result.1) entites updated")
        }
    }
}
