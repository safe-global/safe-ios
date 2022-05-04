//
//  SafeOwnerPickerViewController.swift
//  Multisig
//
//  Created by Vitaly on 02.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Ethereum
import JsonRpc2
import Json
import SafeAbi

class SafeOwnerPickerViewController: ContainerViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var ownerListContentView: UIView!

    private var pullToRefreshControl: UIRefreshControl!

    private var ownerListViewController: ChooseSafeOwnerViewController!
    private var stepLabel: UILabel!
    private let stepNumber: Int = 1
    private let maxSteps: Int = 2

    private var safe: Safe!
    private var safeOwners: [KeyInfo] = []
    private var selectedOwnerPosition: Int = -1

    var onContinue: ((_ ownerToReplace: KeyInfo) -> Void)?

    private var clientGatewayService = App.shared.clientGatewayService
    private var client: JsonRpc2.Client!

    private var currentDataTask: URLSessionTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        //FIXME guard safe, chain
        safe = try! Safe.getSelected()
        client = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: safe.chain!.authenticatedRpcUrl.absoluteString), serializer: JsonRpc2.DefaultSerializer())

        navigationItem.title = "Replace owner"

        headerLabel.setStyle(.secondary)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        ownerListViewController = ChooseSafeOwnerViewController()
        ownerListViewController.onOwnerSelected = { [unowned self] position in
            self.setOwnerSelection(position: position)
        }
        viewControllers = [ownerListViewController]
        displayChild(at: 0, in: ownerListContentView)

        pullToRefreshControl = UIRefreshControl()
        pullToRefreshControl.addTarget(self,
                action: #selector(pullToRefreshChanged),
                for: .valueChanged)
        ownerListViewController.setRefreshControl(pullToRefreshControl)

        continueButton.setText("Continue", .filled)
        continueButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        reloadSafeOwners()
        //TODO: track screen
    }

    @objc private func pullToRefreshChanged() {
        reloadSafeOwners()
    }

    func reloadSafeOwners() {
        ownerListViewController.reloadWithOwners(owners: safeOwners)
    }


    func setOwnerSelection(position: Int) {
        selectedOwnerPosition = position
        continueButton.isEnabled = true
    }
}

class ChooseSafeOwnerViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {


    var onOwnerSelected: ((_ position: Int) -> Void)?

    private var safeOwners: [KeyInfo] = []

    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }

    func setRefreshControl(_ refreshControl: UIRefreshControl) {
        tableView.refreshControl = refreshControl
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.backgroundColor = .backgroundSecondary
        tableView.registerCell(SigningKeyTableViewCell.self)
    }

    @objc func reloadWithOwners(owners: [KeyInfo]) {
        safeOwners = owners
        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        safeOwners.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = safeOwners[indexPath.row]
        let cell = tableView.dequeueCell(SigningKeyTableViewCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configure(keyInfo: keyInfo, chainID: nil)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //TODO: set checkmark
        onOwnerSelected?(indexPath.row)
    }
}
