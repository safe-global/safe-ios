//
//  EnterKeyOrSeedPhraseViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 20.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterKeyOrSeedPhraseViewController: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!

    private var nextButton: UIBarButtonItem!

    convenience init() {
        self.init(namedClass: EnterKeyOrSeedPhraseViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Owner Key"

        nextButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(didTapNextButton(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.rightBarButtonItem = nextButton

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

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTapNextButton(_ sender: Any) {}

    private func updateTextDependentViews(with text: String) {
        placeholderLabel.isHidden = !text.isEmpty
//        nextButtonItem.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension EnterKeyOrSeedPhraseViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextDependentViews(with: textView.text)
    }
}
