//
//  EmailSupportViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import UIKit
import MessageUI

struct EmailSupportViewController: UIViewControllerRepresentable {

    static var isAvailable: Bool { MFMailComposeViewController.canSendMail() }
    var url: URL
    var delegate = MailComposeHandler()

    func makeUIViewController(context: Context) -> UIViewController {
        guard Self.isAvailable else { return UIViewController() }
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = delegate
        mailVC.setToRecipients([url.absoluteString])
        // 08.08.2019: Product decision was not to localise this mail.
        mailVC.setSubject("Feedback")

        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "(unknown)"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let version = "v\(marketingVersion) (\(buildNumber))"
        let safe = try? App.shared.coreDataStack.viewContext.fetch(Safe.fetchRequest().selected()).first
        let address = safe?.address ?? "None"
        let chain = safe != nil ? "\(safe!.chain!.name!) (\(safe!.chain!.id!))" : "None"

        let message = """
        Safe{Wallet} mobile app \(version)
        Safe Account address: \(address)
        Chain: \(chain)
        Feedback:
        """
        mailVC.setMessageBody(message, isHTML: false)

        UINavigationBar.appearance(whenContainedInInstancesOf: [MFMailComposeViewController.self])
            .tintColor = nil

        return mailVC
    }

    func updateUIViewController(_ uiViewController: UIViewController,
                                context: Context) {
        // do nothing
    }
}

class MailComposeHandler: NSObject, MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }

}

struct EmailSupportViewController_Previews: PreviewProvider {
    static var previews: some View {
        EmailSupportViewController(url: URL(string: "support@safe.global")!)
    }
}


