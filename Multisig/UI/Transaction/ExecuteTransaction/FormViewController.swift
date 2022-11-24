//
//  EditFeeFormViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

/// Responsible for creating the fields and field validation
protocol FormModel: AnyObject {
    /// Will be set by the form view controller
    var delegate: FieldDelegate? { get set }
    /// Whether the form is valid.
    var isValid: Bool? { get }
    /// validates the form. Must set the `isValid` to `true` if validation succeeds.
    func validate()
    /// Returns the field views
    func fields() -> [UIView]
}

/// Responsible for reacting to text field focus and validating the form
protocol FieldDelegate: AnyObject {
    func textFieldFocused(_ textField: UITextField)
    func textFieldLostFocus(_ textField: UITextField)
    /// Tells the delegate to redraw the screen to adapt to changed field layout
    func layoutNeeded()
    /// Tells the delegate to validate the whole form
    func validate()
}

/// A form screen
class FormViewController: UITableViewController {
    // responsibilities
    //    layout of fields
    //    reaction to keyboard show/hide
    //    presenter of vc's when needed by fields
    //    validation triggering
    // Using table view because if we need to support sections in the future, this will be easier with the table view.

    var cells: [UITableViewCell] = []
    var model: FormModel!
    var onClose: () -> Void = {}
    var onSave: () -> Void = {}
    var trackingEvent: TrackingEvent?
    var chainId: String?
    var showsCloseButton: Bool = true

    var keyboardBehavior: KeyboardAvoidingBehavior!
    var closeButton: UIBarButtonItem!
    var saveButton: UIBarButtonItem!
    var keyboardToolbar: UIToolbar!

    convenience init(model: FormModel, onClose: @escaping () -> Void) {
        self.init(nibName: nil, bundle: nil)
        self.model = model
        self.model.delegate = self
        self.onClose = onClose
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(model != nil)

        tableView.registerCell(ContainerTableViewCell.self)
        tableView.backgroundColor = .backgroundPrimary
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .none

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: tableView)

        if showsCloseButton {
            closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
            navigationItem.leftBarButtonItem = closeButton
        }

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        navigationItem.rightBarButtonItem = saveButton
        saveButton.isEnabled = false

        keyboardToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapKeyboardDone))
        keyboardToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            done
        ]
        keyboardToolbar.sizeToFit()

        reloadData()
    }

    @objc func didTapCloseButton() {
        onClose()
    }

    @objc func didTapSaveButton() {
        onSave()
    }

    @objc func didTapKeyboardDone() {
        keyboardBehavior.hideKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            var parameters: [String: Any]? = nil
            if (chainId != nil) {
                parameters = ["chain_id": chainId!]
            }
            Tracker.trackEvent(trackingEvent, parameters: parameters)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
        TooltipSource.hideAll()
    }

    func reloadData() {
        let fields = model.fields()
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

    func validate() {
        model.validate()
        saveButton.isEnabled = model.isValid == true
    }
}

extension FormViewController: FieldDelegate {
    func textFieldFocused(_ textField: UITextField) {
        keyboardBehavior.activeResponder = textField
        textField.inputAccessoryView = keyboardToolbar
    }

    func layoutNeeded() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func textFieldLostFocus(_ textField: UITextField) {
        validate()
    }
}
