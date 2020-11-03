//
//  UITableViewCell+UINib.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UIView {
    /// Get nib by this class's name
    /// - Returns: Nib named the same as the cell's class
    class func nib() -> UINib {
        UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }

    /// Reuse identifier by convention - name of the class itslef
    class var reuseID: String {
        String(describing: self)
    }
}

extension UITableView {
    /// Registers a cell using a nib named the same as the cell's class and
    /// reuseID the same as the cell's class name.
    /// - Parameters:
    ///   - aClass: Cell class to use as the convention for nib name and reuseID
    ///   - reuseID: if not nil, the supplied value is used as reuse identifier
    ///     if nil (default), then class's name is used as reuse identifier.
    func registerCell<T: UITableViewCell>(_ aClass: T.Type, reuseID: String? = nil) {
        register(aClass.nib(), forCellReuseIdentifier: reuseID ?? aClass.reuseID)
    }

    /// Dequeues a cell for index path based on the name of the cell class.
    /// - Parameters:
    ///   - aClass: The class to use as the convention for the reuse identifier
    ///   - reuseID: if not nil, this reuse identifier will be used, otherwise the class's name
    ///   - indexPath: index path to pass to the dequeue method of the table view
    /// - Returns: the dequeued cell
    func dequeueCell<T: UITableViewCell>(_ aClass: T.Type, reuseID: String? = nil, for indexPath: IndexPath) -> T {
        dequeueReusableCell(withIdentifier: reuseID ?? aClass.reuseID, for: indexPath) as! T
    }
}
