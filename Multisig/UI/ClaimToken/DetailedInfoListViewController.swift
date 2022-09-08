//
//  DetailedInfoListViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/7/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailedInfoListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    var titleText: String!
    var content: [(title: String?, description: String?)]!
    var trackingEvent: TrackingEvent?

    convenience init(title: String, content: [(title: String?, description: String?)], trackingEvent: TrackingEvent? = nil) {
        self.init(namedClass: DetailedInfoListViewController.self)
        self.titleText = title
        self.content = content
        self.trackingEvent = trackingEvent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
        title = titleText
        tableView.registerCell(DetailedInfoListTableViewCell.self)
    }
}

extension DetailedInfoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        content.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailedInfoListTableViewCell.self)
        let item = content[indexPath.row]

        cell.set(title: item.title, description: item.description)

        return cell
    }
}
