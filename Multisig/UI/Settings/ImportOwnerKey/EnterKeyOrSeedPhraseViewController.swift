//
//  EnterKeyOrSeedPhraseViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterKeyOrSeedPhraseViewController: UIViewController {
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!

    private var nextButton: UIBarButtonItem!

    private var keyboardBehavior: KeyboardAvoidingBehavior!

    convenience init() {
        self.init(namedClass: EnterKeyOrSeedPhraseViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Owner Key"

        keyboardBehavior = KeyboardAvoidingBehavior(scrollView: scrollView)

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.rightBarButtonItem = nextButton
        nextButton.isEnabled = false

        descriptionLabel.setStyle(.body)

        errorLabel.setStyle(GNOTextStyle.callout.color(.gnoTomato))
        errorLabel.isHidden = true

        textView.delegate = self
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.gnoWhitesmoke.cgColor
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.textColor = .gnoDarkBlue
        textView.font = .gnoFont(forTextStyle: .body)
        textView.becomeFirstResponder()

        placeholderLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
        placeholderLabel.text = "Enter private key or seed phrase"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerEnterSeed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc private func didTapNextButton(_ sender: Any) {
        let phrase = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPotentiallyValidSeedPhrase(phrase) {
            guard let seedData = BIP39.seedFromMmemonics(phrase),
                let rootNode = HDNode(seed: seedData)?.derive(path: HDNode.defaultPathMetamaskPrefix,
                                                              derivePrivateKey: true) else {
                setError(GSError.WrongSeedPhrase())
                return
            }
            let vc = KeyPickerController(node: rootNode)
            show(vc, sender: self)
        } else if isValidPK(phrase) {
            let vc = ConfirmPrivateKeyViewController(privateKey: Data(exactlyHex: phrase)!)
            show(vc, sender: self)
        }
    }

    private func updateTextDependentViews(with text: String) {
        placeholderLabel.isHidden = !text.isEmpty
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
        textView.layer.borderColor = error == nil ? UIColor.gnoWhitesmoke.cgColor : UIColor.gnoTomato.cgColor
    }
}

extension EnterKeyOrSeedPhraseViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardBehavior.activeTextView = textView
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTextDependentViews(with: textView.text)
    }
}
