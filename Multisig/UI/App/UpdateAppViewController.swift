//
//  UpdateAppViewController.swift
//  Multisig
//
//  Created by Moaaz on 4/14/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class UpdateAppViewController: UIViewController {
    enum Style {
        case required
        case optional
        case recommended

        var description: String {
            switch self {
            case .required:
                return "Your version of the Safe{Wallet} app is not supported anymore since it is too old. Please update your app"
            case .recommended:
                return "Your version of the Safe{Wallet} app will be deprecated soon. Please update your app."
            case .optional:
                return "There is an update of the Safe{Wallet} app available"
            }
        }

        var trackEvent: TrackingEvent {
            switch self {
            case .optional:
                return .appUpdateOptional
            case .recommended:
                return .appUpdateDeprecatedSoon
            case .required:
                return .appUpdateDeprecated
            }
        }

        var unskippable: Bool {
            self == .required
        }
    }

    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!

    var completion: () -> Void = { }
    var style: Style = .optional

    convenience init(style: Style) {
        self.init(namedClass: UpdateAppViewController.self)
        self.style = style
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel.text = style.description
        descriptionLabel.setStyle(.body)
        updateButton.setText("Update now", .filled)
        skipButton.setText("Skip", .primary)
        skipButton.isHidden = style.unskippable
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(style.trackEvent)
    }

    @IBAction func updateButtonTouched(_ sender: Any) {
        let url = App.configuration.contact.appStoreReviewURL
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        if !style.unskippable {
            completion()
        }
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        completion()
    }
}
