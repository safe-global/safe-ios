//
//  ChooseGuardianViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseGuardianViewController: LoadableViewController {

    private var stepLabel: UILabel!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 3

    private var guardians: [Guardian] = []
    private var filteredGuardians: [Guardian] = []

    var onSelected: ((Guardian) -> ())?
    var onReloaded: (() -> ())?

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ViewControllerFactory.makeTransparentNavigationBar(self)
        navigationItem.hidesBackButton = false

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        tableView.registerCell(GuardianTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorStyle = .none

        emptyView.setText("No guardian found")
        emptyView.setImage(UIImage(named: "ico-delegate-placeholder")!)
    }

    func filterData(searchTerm: String) {
        let searchTerm = searchTerm.lowercased()
        if !searchTerm.isEmpty {
            filteredGuardians = guardians.filter { guardian in
                return guardian.name?.lowercased().contains(searchTerm) ?? false ||
                guardian.ensName?.lowercased().contains(searchTerm) ?? false ||
                guardian.address == Address(searchTerm)
            }

        } else {
            filteredGuardians = guardians
        }
        if isEmpty {
            showOnly(view: emptyView)
        } else {
            showOnly(view: tableView)
        }
        tableView.reloadData()
    }

    override var isEmpty: Bool { filteredGuardians.isEmpty }

    override func reloadData() {
        super.reloadData()
        guardians = []
        if let filepath = Bundle.main.path(forResource: "Guardians", ofType: "csv") {
            do {
                let contents = try String(contentsOfFile: filepath)
                createGuardiansFrom(csv: contents)
                filteredGuardians = guardians
                onSuccess()
                onReloaded?()
            } catch {
                onError(GSError.error(description: "Failed to load guardians"))
                onReloaded?()
            }
        } else {
            onError(GSError.error(description: "Failed to load guardians"))
            onReloaded?()
        }
    }

    private func createGuardiansFrom(csv: String) {

        let entites = csv.split(whereSeparator: \.isNewline).dropFirst().prefix(8)
        entites.forEach { entry in

            let values: [String] = entry.components(separatedBy: ",")

            let name = values[1]
            let reason = values[2]
            let previousContribution = values[3]
            let address = Address(values[4]) ?? Address.zero
            let ensName = address == Address.zero ? values[4] : nil
            let imageUrl = values[5]

            let guardian = Guardian(name: name,
                                    reason: reason,
                                    previousContribution: previousContribution,
                                    address: address,
                                    ensName: ensName,
                                    imageURLString: imageUrl)
            
            guardians.append(guardian)
        }
    }
}

extension ChooseGuardianViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredGuardians.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(GuardianTableViewCell.self)
        cell.set(guardian: filteredGuardians[indexPath.row])
        cell.tableView = tableView
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = GuardianDetailsViewController()
        vc.onSelected = onSelected
        vc.guardian = filteredGuardians[indexPath.row]
        show(vc, sender: nil)
    }
}

struct Guardian {
    let name: String?
    let reason: String?
    let previousContribution: String?
    let address: Address
    let ensName: String?
    let imageURLString: String?

    var imageURL: URL? {
        imageURLString == nil ? nil : URL(string: imageURLString!)
    }
}
