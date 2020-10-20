//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class BalancesViewController: UIViewController {

    // contentView - reference to the currently presented content subview
    // reference to data controller

    override func viewDidLoad() {
        super.viewDidLoad()

        // create and store loading view
        //      view with activity indicator
        // create and store noData view
        //      view with status message and refresh control
        //      on refresh -> reload data
        // create and store table view
        //      delegate and data source is self
        //      create custom cell for balances
        //          image view -> load from URL, show placeholder
        //          text - already formatted
        //      on refresh -> reload data

    }

    // viewWillAppear
    //  if data is dirty, reload it

    // show loading
    // show status view
    // show results view
    //      show the results view
    //      remove other view from hierarchy

}

// RemoteDataController - reusable logic of loading the data with a network request inside a view controller
// cancellable data task - reference to the data task that will be cancelled on certain events
// reference to containing view controller
// state = dirty | clean

// init
//      reference the containing view controller implementing the protocol
//
// subscribe for events:
//      SelectedSafeChanged -> reloadData()
//      App Enters Foreground -> reloadData()

// reload data
//     if view is off-screen -> state = dirty; exit
//
//     cancel the current data task
//     show loading view
//     fetch data with completion
//          on failed
//              show status view
//              show snackbar
//              state = clean
//          on success
//              transform results to view-expected data
//              store the data
//              show table view
//              reload table view
//              state = clean
