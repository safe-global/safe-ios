//
//  ChooseGuardianViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/27/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChooseGuardianViewController: LoadableViewController {
    var stepNumber: Int = 1
    var maxSteps: Int = 3

    var guardians: [Guardian] = []
    var onSelect: ((Guardian) -> ())?
    private var stepLabel: UILabel!
    
    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(GuardianTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorStyle = .none
        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.title = "Safe Token Claiming"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)

        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"
    }

    override func reloadData() {
        super.reloadData()
        guardians = []
        if let filepath = Bundle.main.path(forResource: "Guardians", ofType: "csv") {
            do {
                let contents = try String(contentsOfFile: filepath)
                createGuardiansFrom(csv: contents)
                onSuccess()
            } catch {
                onError(GSError.error(description: "Failed to load guardians"))
            }
        } else {
            onError(GSError.error(description: "Failed to load guardians"))
        }
    }

    private func createGuardiansFrom(csv: String) {

        let entites = csv.split(whereSeparator: \.isNewline).dropFirst().prefix(2)
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
        guardians.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(GuardianTableViewCell.self)
        cell.set(guardian: guardians[indexPath.row])
        cell.tableView = tableView
        cell.onSelect = { [unowned self] in
            //onSelect?(guardians[indexPath.row])


            let vc = GuardianDetailsViewController()
            vc.guardian = guardians[indexPath.row]
            show(vc, sender: nil)
        }

        return cell
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
