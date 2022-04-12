//
//  VerifyPhraseViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class VerifyPhraseViewController: UIViewController {

    enum State {
        case question
        case checking
        case correct
        case incorrect
        case next
        case completed
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// states
    // prompt/waiting -> checking -> correct | incorrect
    // correct -> next | completed
    // incorrect -> prompt

// waiting answer -> checking -> correct -> next | completed
//                               incorrect -> restart
// can go back at any time except completed.

// words - array

// word view: empty | normal | correct | incorrect | checking

// question
    // word number
    // correct choice
    // choices: words

// questions
