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
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.rightBarButtonItem = nextButton

        descriptionLabel.setStyle(.body)

        errorLabel.setStyle(GNOTextStyle.callout.color(.gnoTomato))
        errorLabel.isHidden = true

        textView.delegate = self
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.gnoWhitesmoke.cgColor
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 14)
        textView.textColor = .gnoDarkBlue
        textView.font = .gnoFont(forTextStyle: .body)

        placeholderLabel.setStyle(GNOTextStyle.body.color(.gnoMediumGrey))
        placeholderLabel.text = "Enter private key or seed phrase"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardBehavior.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardBehavior.stop()
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTapNextButton(_ sender: Any) {
        setError(GSError.NoInternet())
    }

    private func updateTextDependentViews(with text: String) {
        placeholderLabel.isHidden = !text.isEmpty
        setError(nil)
//        nextButtonItem.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
