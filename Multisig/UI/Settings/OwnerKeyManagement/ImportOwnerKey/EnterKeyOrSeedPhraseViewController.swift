//
//  EnterKeyOrSeedPhraseViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterKeyOrSeedPhraseViewController: UIViewController {

    var completion: () -> Void = {}

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var textField: GMTextField!
    private var nextButton: UIBarButtonItem!

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    private(set) var seedNode: HDNode?
    private(set) var privateKey: PrivateKey?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Owner Key"

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton
        nextButton.isEnabled = false

        descriptionLabel.setStyle(.primary)

        errorLabel.setStyle(.error)
        errorLabel.isHidden = true

        textField.delegate = self
        textField.becomeFirstResponder()

        textField.placeholder = "Enter private key or seed phrase"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ownerEnterSeed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let phrase = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if isPotentiallyValidSeedPhrase(phrase) {
            nextButton.isEnabled = false
            guard let seedData = BIP39.seedFromMmemonics(phrase),
                let rootNode = HDNode(seed: seedData)?.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                              derivePrivateKey: true) else {
                nextButton.isEnabled = true
                setError(GSError.WrongSeedPhrase())
                return
            }
            nextButton.isEnabled = true
            self.seedNode = rootNode
            self.completion()
        } else if isValidPK(phrase),
                  // we need to use Data(ethHex:) here in case if some software
                  // exported private key without a leading 0
                  let privateKey = try? PrivateKey(data: Data(ethHex: phrase)) {

            self.privateKey = privateKey
            self.completion()
        }
    }

    private func updateTextDependentViews(with text: String) {
        setError(nil)
        let phrase = text.trimmingCharacters(in: .whitespacesAndNewlines)
        nextButton.isEnabled = isPotentiallyValidSeedPhrase(phrase) || isValidPK(phrase)
    }

    private func isPotentiallyValidSeedPhrase(_ phrase: String) -> Bool {
        [12, 15, 18, 21, 24].contains(phrase.split(separator: " ").count)
    }

    private func isValidPK(_ pk: String) -> Bool {
        if let data = Data(exactlyHex: pk),
           data.count == 32,
           data != Data(hex: "0x0000000000000000000000000000000000000000000000000000000000000000") {
            return true
        }
        return false
    }

    private func setError(_ error: Error?) {
        errorLabel.text = error?.localizedDescription
        errorLabel.isHidden = error == nil
        textField.hasError = error != nil
    }
}

extension EnterKeyOrSeedPhraseViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardBehavior.activeTextField = textField
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let oldText = textField.text as? NSString {
            let newText = oldText.replacingCharacters(in: range, with: string)
            updateTextDependentViews(with: newText)
        } else {
            updateTextDependentViews(with: string)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapNextButton(textField)
        return true
    }
}

class GMTextField: UITextField {
    var textInset: UIEdgeInsets = .zero

    var hasError: Bool = false {
        didSet {
            layer.borderColor = hasError ? UIColor.error.cgColor: UIColor.labelTertiary.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        layer.borderWidth = 2
        layer.cornerRadius = 10
        hasError = false
        textInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        setStyle(.primary)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        super.textRect(forBounds: bounds).inset(by: textInset)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        super.editingRect(forBounds: bounds).inset(by: textInset)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        super.clearButtonRect(forBounds: bounds).offsetBy(dx: -textInset.right, dy: 0)
    }
}
