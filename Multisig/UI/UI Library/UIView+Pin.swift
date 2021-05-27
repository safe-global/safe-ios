//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {

    func wrapAroundDynamicHeightView(_ contentView: UIView) {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor)])
    }

    func wrapAroundDynamicHeightView(_ contentView: UIView, insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(insets.left)),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: CGFloat(-insets.right)),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: CGFloat(insets.top)),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: CGFloat(insets.bottom))])
    }

    func pintToTop(of view: UIView, height: CGFloat) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            heightAnchor.constraint(equalToConstant: CGFloat(height))])
    }

    func wrapAroundView(_ contentView: UIView) {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
}
