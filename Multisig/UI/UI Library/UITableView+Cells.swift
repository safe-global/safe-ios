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
                   icon: String? = nil,
                   detail: String? = nil,
                   indexPath: IndexPath,
                   withDisclosure: Bool = true,
                   disclosureImage: UIImage? = nil,
                   supplementaryImage: UIImage? = nil,
                   canSelect: Bool = true) -> BasicCell {
        let cell = dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setIcon(icon)
        cell.setDetail(detail)
        cell.setSupplementary(supplementaryImage)
        if !withDisclosure {
            cell.setDisclosureImage(disclosureImage)
        }
        if !canSelect {
            cell.selectionStyle = .none
        }
        return cell
    }

    func basicCell(name: String,
                   iconURL: URL? = nil,
                   placeholder: UIImage? = nil,
                   detail: String? = nil,
                   indexPath: IndexPath,
                   withDisclosure: Bool = true,
                   disclosureImage: UIImage? = nil,
                   supplementaryImage: UIImage? = nil,
                   canSelect: Bool = true) -> BasicCell {
        let cell = dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setIcon(url: iconURL, placeholder: placeholder)
        cell.setDetail(detail)
        cell.setSupplementary(supplementaryImage)
        
        if !withDisclosure {
            cell.setDisclosureImage(disclosureImage)
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
                      canSelect: Bool = true,
                      placeholderImage: UIImage? = nil) -> UITableViewCell {
        let cell = dequeueCell(DetailedCell.self, for: indexPath)
        cell.setImage(url: imageUrl, placeholder: placeholderImage)
        cell.setHeader(header)
        cell.setDescription(description)
        if !canSelect {
            cell.selectionStyle = .none
        }

        return cell
    }

    func infoCell(name: String,
                  info: String,
                  indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell(InfoCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setInfo(info)
        cell.selectionStyle = .none
        return cell
    }

    func addressDetailsCell(address: Address, showQRCode: Bool = false, indexPath: IndexPath, badgeName: String? = nil) -> UITableViewCell {
        let cell = dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, badgeName: badgeName, showQRCode: showQRCode)
        return cell
    }

    func switchCell(for indexPath: IndexPath, with text: String, isOn: Bool) -> SwitchTableViewCell {
        let cell = dequeueCell(SwitchTableViewCell.self, for: indexPath)
        cell.setText(text)
        cell.setOn(isOn, animated: false)
        return cell
    }

    func helpCell(for indexPath: IndexPath,
                  with text: String,
                  backgroundColor: UIColor = .backgroundPrimary,
                  textStyle: GNOTextStyle = .secondary) -> UITableViewCell {
        let cell = dequeueCell(UITableViewCell.self, reuseID: "HelpCell", for: indexPath)
        cell.textLabel?.setStyle(.secondary)
        cell.backgroundColor = backgroundColor
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        
        return cell
    }

    func helpLinkCell(text: String, url: URL, indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell(HelpLinkTableViewCell.self, for: indexPath)
        cell.descriptionLabel.hyperLinkLabel(linkText: text)
        cell.url = url
        return cell
    }

	func removeCell(indexPath: IndexPath, title: String, onRemove: (() -> Void)?) -> UITableViewCell {
        let cell = dequeueCell(RemoveCell.self, for: indexPath)
        cell.set(title: title)
        cell.onRemove = onRemove
        cell.selectionStyle = .none
        return cell
    }
}
