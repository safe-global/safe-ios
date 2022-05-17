//
//  SuccessViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Lottie

class SuccessViewController: UIViewController {

    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!

    private var titleText: String?
    private var bodyText: String?
    private var primaryAction: String?
    private var secondaryAction: String?
    private var trackingEvent: TrackingEvent?

    var trackingParams: [String: Any]? = nil

    var onDone: (_ didTapPrimary: Bool) -> Void = { _ in }
    
    convenience init(
        titleText: String?,
        bodyText: String?,
        primaryAction: String?,
        secondaryAction: String?,
        trackingEvent: TrackingEvent?
    ) {
        self.init(nibName: nil, bundle: nil)
        self.titleText = titleText
        self.bodyText = bodyText
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.trackingEvent = trackingEvent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        navigationItem.backButtonTitle = "Back"

        titleLabel.setStyle(.headline)
        bodyLabel.setStyle(.secondary)

        titleLabel.text = titleText
        bodyLabel.text = bodyText

        if let primary = primaryAction, let secondary = secondaryAction {
            primaryButton.setText(primary, .filled)
            secondaryButton.setText(secondary, .plain)
        } else if let primary = primaryAction {
            primaryButton.setText(primary, .filled)
            secondaryButton.isHidden = true
        } else if let secondary = secondaryAction {
            secondaryButton.setText(secondary, .plain)
            primaryButton.isHidden = true
        } else {
            primaryButton.setText("Done", .filled)
            secondaryButton.isHidden = true
        }

        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()

        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent, parameters: trackingParams)
        }
    }

    @IBAction func didTapDone(_ sender: Any) {
        onDone(false)
    }

    @IBAction func viewDetailsClicked(_ sender: Any) {
        onDone(true)
    }
}
