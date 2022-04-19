//
//  EnterKeyOrSeedPhraseViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterKeyOrSeedPhraseViewController: UIViewController {

    var completion: () -> Void = { }

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var placeholderLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!

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

        textView.textContentType = .password
        textView.delegate = self
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.labelTertiary.cgColor
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.setStyle(.primary)
        
        textView.becomeFirstResponder()

        placeholderLabel.setStyle(.tertiary)
        placeholderLabel.text = "Enter private key or seed phrase"
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
        let phrase = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        textView.layer.borderColor = error == nil ? UIColor.labelTertiary.cgColor : UIColor.error.cgColor
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
