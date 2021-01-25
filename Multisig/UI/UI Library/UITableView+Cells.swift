//
//  UITableViewCell+Extension.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 25.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

extension UITableView {
    func basicCell(name: String,
                   indexPath: IndexPath,
                   withDisclosure: Bool = true,
                   canSelect: Bool = true) -> UITableViewCell {
        let cell = dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        if !withDisclosure {
            cell.setDisclosureImage(nil)
        }
        if !canSelect {
            cell.selectionStyle = .none
        }
        return cell
    }

    func detailedCell(imageUrl: URL?,
                      header: String?,
                      description: String?,
                      indexPath: IndexPath,
                      canSelect: Bool = true) -> UITableViewCell {
        let cell = dequeueCell(DetailedCell.self, for: indexPath)
        cell.setImage(url: imageUrl)
        cell.setHeader(header)
        cell.setDescription(description)
        if !canSelect {
            cell.selectionStyle = .none
        }

        return cell
    }
}
