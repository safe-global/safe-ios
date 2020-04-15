//
//  SafariViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafariServices
import SwiftUI

struct SafariViewController: UIViewControllerRepresentable {

    var url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController,
                                context: Context) {
        // do nothing
    }
}

struct SafariViewController_Previews: PreviewProvider {
    static var previews: some View {
        SafariViewController(url: URL(string: "https://apple.com")!)
    }
}
