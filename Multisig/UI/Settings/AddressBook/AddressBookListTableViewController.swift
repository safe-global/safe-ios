//
//  AddressbookListTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddressBookListTableViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    var chainId: String!
    var entities: [AddressBookEntity] = []

    private var addButton: UIBarButtonItem!
    override var isEmpty: Bool {
        entities.isEmpty
    }

    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(chainId != nil, "Developer error: expect to have a chainId")

        title = "Address Book"

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .primaryBackground

        tableView.registerCell(DetailAccountCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setText("There are no address book entities")
        emptyView.setImage(UIImage(named: "ico-no-address-book")!)

        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton(_:)))
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

    @objc private func didTapAddButton(_ sender: Any) {
        let vc = ViewControllerFactory.addOwnerViewController { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
        present(vc, animated: true)
    }
    
    @objc override func reloadData() {
        entities = AddressBookEntity.by(chainId: chainId) ?? []
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        let entity = entities[indexPath.row]

        cell.setAccount(address: entity.addressValue, label: entity.name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEdit(entity: entities[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entity = entities[indexPath.row]

        var actions = [UIContextualAction]()
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, completion in
            showEdit(entity: entities[indexPath.row])
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
            AddressBookEntity.update(entity.displayAddress, chainId: chainId, name: name)
            notificationCenter.post(name: .addressbookChanged, object: self, userInfo: nil)
        }

        show(enterNameVC, sender: nil)
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
