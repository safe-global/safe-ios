//
//  SafeLoadedViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/19/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeLoadedViewController: UIViewController {

    @IBOutlet weak var safeInfoView: SafeInfoViewV2!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var importOwnerKeyButton: UIButton!

    private var safe: Safe!
    var completion: () -> Void = { }
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            safe = try Safe.getSelected()!
            titleLabel.setStyle(.title3)
            importOwnerKeyButton.setText("Import owner key", .filled)
            skipButton.setText("Skip", .plain)
            safeInfoView.set(safe.name)
            safeInfoView.setAddress(safe.addressValue, label: nil)
        } catch {
            //onError(GSError.error(description: "Failed to load safe settings", error: error))
        }
    }

    @IBAction func importOwnerButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerImport)
        
    }

    @IBAction func skipButtonTouched(_ sender: Any) {
        Tracker.shared.track(event: TrackingEvent.userOnboardingOwnerSkip)
        dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
