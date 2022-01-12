//
//  EditFeeFormViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit


// responsibilities
//    layout of fields
//    reaction to keyboard show/hide
//    presenter of vc's when needed by fields
//    validation triggering
//    navigation between fields

// chose table view because if we need to support sections in the future, this will be easier with the table view.
class FormViewController: UITableViewController {

    var cells: [UITableViewCell] = []
    var model: FeeLegacyFormUIModel!
    var fieldFactory: FeeLegacyFieldFactory!
    var onClose: () -> Void = {}
    var onSave: () -> Void = {}

    var keyboardBehavior: KeyboardAvoidingBehavior!
    var closeButton: UIBarButtonItem!
    var saveButton: UIBarButtonItem!

    convenience init(model: FeeLegacyFormUIModel, factory: FeeLegacyFieldFactory, onClose: @escaping () -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.model = model
        self.fieldFactory = factory
        self.onClose = onClose
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(model != nil)

        tableView.registerCell(ContainerTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .none

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: tableView)

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton
        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton


        reloadData()
    }

    @objc func didTapCloseButton() {
        onClose()
    }

    @objc func didTapSaveButton() {
        onSave()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    func reloadData() {
        let fields = fieldFactory.fields(from: model, keyboardBehavior: keyboardBehavior)
        self.cells = fields.map { view in
            let cell = tableView.dequeueCell(ContainerTableViewCell.self)
            cell.setContent(view)
            cell.selectionStyle = .none
            return cell
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

//    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        let cell = cells[indexPath.row] as! ContainerTableViewCell
//        print(cell)
//        return cell.contentView.bounds.height
//    }

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let cell = cells[indexPath.row] as! ContainerTableViewCell
//        let height = cell.cellContentView.frame.height
//        print(indexPath, height, cell.frame)
//        return height
//    }

    // keyboardBehavior.activeResponder = field.uiResponder
}

import Solidity

// also factory for field UI views
struct FeeLegacyFormUIModel {
    var nonce: Sol.UInt64? // no value in the field
    var gas: Sol.UInt64?
    var gasPrice: Sol.UInt256?
    var helpLink: URL
}

class FeeLegacyFieldFactory {
    func fields(from model: FeeLegacyFormUIModel, keyboardBehavior: KeyboardAvoidingBehavior) -> [UIView] {
        let nonce = LabeledTextField()
        nonce.infoLabel.setText(
            "Nonce",
            description: "Transaction count of the execution account",
            style: .primary
        )
        nonce.gnoTextField.setPlaceholder("Nonce")
        nonce.gnoTextField.text = model.nonce.map { String(describing: $0) }
        nonce.gnoTextField.setError(GSError.error(description: "Invalid nonce. Use another value"))
        nonce.onTextFieldDidBeginEditing = { [weak keyboardBehavior] _, tf in
            keyboardBehavior?.activeResponder = tf
        }

        let gas = LabeledTextField()
        gas.infoLabel.setText(
            "Gas limit",
            description: "Maximum gas that this transaction can spend. Unused gas will be refunded",
            style: .primary
        )
        gas.gnoTextField.setPlaceholder("Gas limit")
        gas.gnoTextField.text = model.gas.map { String(describing: $0) }
        gas.gnoTextField.setError(GSError.error(description: "Invalid gas limit. Use another value. Long line long line long line long line"))
        gas.onTextFieldDidBeginEditing = { [weak keyboardBehavior] _, tf in
            keyboardBehavior?.activeResponder = tf
        }

        let gasPrice = LabeledTextField()
        gasPrice.infoLabel.setText(
            "Gas price (GWEI)",
            description: "Price per 1 gas in Gwei price units",
            style: .primary
        )
        gasPrice.gnoTextField.setPlaceholder("Gas price (GWEI)")
        gasPrice.gnoTextField.text = model.gasPrice.map { String(describing: $0) }
        gasPrice.gnoTextField.setError(GSError.error(description: "Invalid gas price. Use another value"))
        gasPrice.setCaption("Total estimated fee: 0.00604 ETH")
        gasPrice.onTextFieldDidBeginEditing = { [weak keyboardBehavior] _, tf in
            keyboardBehavior?.activeResponder = tf
        }

        let help = HyperlinkButtonView()
        help.setText("How do I configure these details manually?")
        help.url = model.helpLink

        return [nonce, gas, gasPrice, help]
    }
}


struct Fee1559FormUIModel {
    var nonce: Sol.UInt64? // no value in the field
    var gas: Sol.UInt64?
    var maxFeePerGas: Sol.UInt256?
    var maxPriorityFee: Sol.UInt256?
}

// field might have multiple text fields
// field might have a text view
// anyway, activeResponder

// Form - whole screen should be inside scroll view
    // fields
        // input field
            // reference to the form?
            // name label
            // description
            // placeholder (hint)
            // error text
            // validator
                // check that the partial input is valid while the user enters something
                // check that the final value is valid
                // validation can take time (making network request)
            // 'value' formatter (could be generic to support any value type)
                // text -> value
                // value -> text
                // should be sync/immediate
            // 'error' value?
            // 'default' value?
            // 'hidden'
            // 'enabled'
            // 'min' and 'max' values
            // 'focused' or 'active'
            // 'debouncing'
        // address field
            // different ways of input
            // validator
            // value formatter
            // might want to have reference to presenting controller

        // 'estimated fee' field
            // calculates the fee price from the inputs
            // show fiat amount?

        // 'submit' button?
            // in navigation bar
            // in the form bottom? - sticks to bottom?

        // 'link' field

    // form validator
        // check that the whole form is valid

    // value transformer from the form content to the model object / modifying the model object...

// UI behavior: keyboard to scroll to the editable field (focus on the field)
