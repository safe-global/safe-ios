//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit

class SeedPhraseViewController: UIViewController {

    @IBOutlet weak var seedPhraseView: SeedPhraseView!

    var seedPhrase: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        seedPhraseView.words = seedPhrase.enumerated().map {
            SeedWord(index: $0.offset, value: $0.element)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        seedPhraseView.update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.exportSeed)
    }

}

struct SeedWord {
    var index: Int
    var value: String

    var number: String {
        return String(index + 1)
    }
}
