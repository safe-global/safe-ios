//
//  ChangeDisplayModeTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/6/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChangeDisplayModeTableViewController: UITableViewController {
    private let items = [UIUserInterfaceStyle.unspecified, UIUserInterfaceStyle.light, UIUserInterfaceStyle.dark]

    private var selectedDisplayMode: UIUserInterfaceStyle {
        get {
            traitCollection.userInterfaceStyle
        }
        set {
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = newValue
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Appearance"

        tableView.registerCell(UITableViewCell.self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell!
        cell = tableView.dequeueCell(UITableViewCell.self, for: indexPath)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: UITableViewCell.self.description())
        }
        cell.textLabel?.text = "\(items[indexPath.row].rawValue)"
        cell.isSelected = items[indexPath.row] == selectedDisplayMode
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedDisplayMode = items[indexPath.row]
        tableView.reloadData()
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
