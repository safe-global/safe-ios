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
    private var safeOwners: [AddressInfo] = []
    private var selectedOwnerPosition: Int = -1

    var onContinue: ((_ previousOwner: Address?, _ ownerToReplace: Address) -> Void)?

    private var clientGatewayService = App.shared.clientGatewayService
    private var client: JsonRpc2.Client!

    private var currentDataTask: URLSessionTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        //FIXME guard safe, chain
        safe = try! Safe.getSelected()
        client = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: safe.chain!.authenticatedRpcUrl.absoluteString), serializer: JsonRpc2.DefaultSerializer())

        navigationItem.title = "Replace owner"

        headerLabel.setStyle(.body)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.calloutTertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        ownerListViewController = ChooseSafeOwnerViewController(safe: safe)
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
        Tracker.trackEvent(.replaceOwnerSelect)
        reloadSafeOwners()
    }

    @objc private func pullToRefreshChanged() {
        reloadSafeOwners()
    }

    func reloadSafeOwners() {
        currentDataTask?.cancel()
        currentDataTask = SafeTransactionController.shared.getOwners(safe: safe.addressValue, chain: safe.chain!) { [weak self] result in

            guard let self = self else {
                return
            }

            switch result {

            case .failure(let error):

                self.ownerListViewController.onError(GSError.error(description: "Failed to load Safe Account owners", error: GSError.detailedError(from: error)))
                self.pullToRefreshControl.endRefreshing()

            case .success(let owners):
                self.safeOwners = owners.compactMap { owner in
                    AddressInfo.init(address: owner)
                }
                self.pullToRefreshControl.endRefreshing()
                self.ownerListViewController.reloadWithOwners(owners: self.safeOwners)
            }
        }
    }

    func setOwnerSelection(position: Int) {
        selectedOwnerPosition = position
        continueButton.isEnabled = true
    }

    @IBAction func didTapContinue(_ sender: Any) {
        let ownerToReplace = safeOwners[selectedOwnerPosition].address
        let prevOwner = selectedOwnerPosition > 0 ? safeOwners[selectedOwnerPosition - 1].address : nil
        onContinue?(prevOwner, ownerToReplace)
    }
}

class ChooseSafeOwnerViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {


    var onOwnerSelected: ((_ position: Int) -> Void)?

    private var safe: Safe!
    private var safeOwners: [AddressInfo] = []
    private var selectedOwner: Int = -1

    convenience init(safe: Safe) {
        self.init(namedClass: LoadableViewController.self)
        self.safe = safe
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
        tableView.registerCell(SafeOwnerCell.self)
    }

    func reloadWithOwners(owners: [AddressInfo]) {
        safeOwners = owners
        DispatchQueue.main.async { [unowned self] in
            self.onSuccess()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        safeOwners.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let safeOwnerInfo = safeOwners[indexPath.row]
        let cell = tableView.dequeueCell(SafeOwnerCell.self, for: indexPath)

        let keyInfo = try? KeyInfo.keys(addresses: [safeOwnerInfo.address]).first
        let (name, _) = NamingPolicy.name(for: safeOwnerInfo.address,
                                                    info: safeOwnerInfo,
                                                    chainId: safe.chain!.id!)
        cell.setAccount(
            address: safeOwnerInfo.address,
            selected: selectedOwner == indexPath.row,
            name: name,
            imageUri: nil,
            badgeName:  keyInfo?.keyType.badgeName,
            prefix: safe.chain!.shortName)
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let oldSelection = selectedOwner
        selectedOwner = indexPath.row

        var updatedPaths = [IndexPath(item: selectedOwner, section: 0)]
        if oldSelection >= 0 {
            updatedPaths.append(IndexPath(item: oldSelection, section: 0))
        }

        tableView.beginUpdates()
        do {
            tableView.reloadRows(at: updatedPaths, with: .automatic)
        }
        tableView.endUpdates()

        onOwnerSelected?(indexPath.row)
    }
}
