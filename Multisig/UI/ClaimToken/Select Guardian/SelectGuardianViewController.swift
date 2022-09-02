//
//  SelectGuardianViewController.swift
//  Multisig
//
//  Created by Vitaly on 28.07.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectGuardianViewController: ContainerViewController, UISearchBarDelegate {

    private let guardiansController = GuardianListViewController()

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var guardiansView: UIView!

    private var stepLabel: UILabel!
    private var stepNumber: Int = 2
    private var maxSteps: Int = 4
    private var keyboardBehavior: KeyboardAvoidingBehavior!

    var onSelected: ((Guardian) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose a delegate"
        ViewControllerFactory.removeNavigationBarBorder(self)

        stepLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 21))
        stepLabel.textAlignment = .right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stepLabel)
        stepLabel.setStyle(.tertiary)
        stepLabel.text = "\(stepNumber) of \(maxSteps)"

        searchBar.placeholder = "Name, address or ENS"
        searchBar.delegate = self

        guardiansController.onReloaded = { [unowned self] in
            searchBar.text = ""
        }
        guardiansController.onSelected = onSelected

        viewControllers = [
            guardiansController
        ]
        displayChild(at: 0, in: guardiansView)

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: guardiansController.tableView)
        keyboardBehavior.hidesKeyboardOnTap = false
        searchBar.searchTextField.delegate = self
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        guardiansController.filterData(searchTerm: searchText)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start(hidesKeyboardOnTap: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }
}

extension SelectGuardianViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }
}
