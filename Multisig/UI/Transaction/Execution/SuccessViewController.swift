//
//  SuccessViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 14.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SuccessViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!

    private var titleText: String?
    private var bodyText: String?
    private var doneTitle: String?
    private var trackingEvent: TrackingEvent?

    var trackingParams: [String: Any]? = nil

    var onDone: () -> Void = { }
    
    convenience init(
        titleText: String?,
        bodyText: String?,
        doneTitle: String?,
        trackingEvent: TrackingEvent?
    ) {
        self.init(nibName: nil, bundle: nil)
        self.titleText = titleText
        self.bodyText = bodyText
        self.doneTitle = doneTitle
        self.trackingEvent = trackingEvent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        navigationItem.backButtonTitle = "Back"

        titleLabel.setStyle(.headline)
        bodyLabel.setStyle(.primary)

        titleLabel.text = titleText
        bodyLabel.text = bodyText
        doneButton.setText(doneTitle ?? "Done", .filled)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let trackingEvent = trackingEvent else {
            return
        }

        Tracker.trackEvent(trackingEvent, parameters: trackingParams)
    }
    
    @IBAction func viewDetailsClicked(_ sender: Any) {
        //TODO check if resetting of the property is needed
        self.navigationController?.isNavigationBarHidden = false

        onDone()
    }
}
