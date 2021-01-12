//
//  UITableView+Reusable.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 03.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

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

    /// Registers a HeaderFooterView using a nib named the same as the view's class and
    /// reuseID the same as the view's class name.
    /// - Parameters:
    ///   - aClass: View class to use as the convention for nib name and reuseID
    ///   - reuseID: if not nil, the supplied value is used as reuse identifier
    ///     if nil (default), then class's name is used as reuse identifier.
    func registerHeaderFooterView<T: UITableViewHeaderFooterView>(_ aClass: T.Type, reuseID: String? = nil) {
        register(aClass.nib(), forHeaderFooterViewReuseIdentifier: reuseID ?? aClass.reuseID)
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

    func dequeueCell<T: UITableViewCell>(_ aClass: T.Type, reuseID: String? = nil) -> T {
        dequeueReusableCell(withIdentifier: reuseID ?? aClass.reuseID)! as! T
    }

    /// Dequeues a HeaderFooterView based on the name of the view class.
    /// - Parameters:
    ///   - aClass: The class to use as the convention for the reuse identifier
    ///   - reuseID: if not nil, this reuse identifier will be used, otherwise the class's name
    /// - Returns: the dequeued view
    func dequeueHeaderFooterView<T: UITableViewHeaderFooterView>(_ aClass: T.Type, reuseID: String? = nil) -> T {
        dequeueReusableHeaderFooterView(withIdentifier: reuseID ?? aClass.reuseID) as! T
    }
}
