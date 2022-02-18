//
// Created by Dmitry Bespalov on 18.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SendTransactionRequestViewController: UIViewController {

    var controller: WebConnectionController!
    var connection: WebConnection!
    var request: WebConnectionSendTransactionRequest!
    var onFinish: () -> Void = { }

}
