//
//  UINibView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// View that initializes itself from the nib named the same as the class name.
class UINibView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Initializes the view. If you override it, make sure to call super
    /// in order to load the view contents.
    func commonInit() {
        autoloadFromNib()
    }
}

extension UIView {
    /// Loads the nib named the same as class name and adds contents of the
    /// nib to this instances
    func autoloadFromNib() {
        let name = String(describing: type(of: self))
        let bundle = Bundle(for: Self.self)
        loadFromNib(name: name, bundle: bundle, owner: self)
    }

    /// Adds first root view of the nib to the subview and makes that subview
    /// resizable with the height and width of the view
    /// - Parameters:
    ///   - name: name of the nib to load from
    ///   - bundle: bundle of the nib
    ///   - owner: file owner in the nib
    func loadFromNib(name: String, bundle: Bundle?, owner: Any?) {
        let nib = UINib(nibName: name, bundle: bundle)
        let content = nib.instantiate(withOwner: owner, options: nil)
        let view = content.first as! UIView
        if view is UIStackView {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                widthAnchor.constraint(equalTo: view.widthAnchor),
                heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        } else {
            view.frame = self.bounds
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            addSubview(view)
        }
    }
}
