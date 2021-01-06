//
//  ActionDetailViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ActionDetailViewController: UITableViewController {
    private var dataDecoded: SCG.DataDecoded?
    private var data: DataString?
    private var customTitle: String?

    convenience init(_ dataDecoded: SCG.DataDecoded?, data: DataString? = nil, title: String? = nil) {
        self.init()
        self.dataDecoded = dataDecoded
        self.data = data
        self.customTitle = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(ActionDetailTextCell.self)
        tableView.registerCell(ActionDetailExpandableCell.self)
        tableView.registerCell(ActionDetailAddressCell.self)
        tableView.separatorStyle = .none
        tableView.contentInset = .init(top: 24, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.transactionsDetailsAction)
    }

    private func reloadData() {
        navigationItem.title = dataDecoded?.method ?? customTitle
        cells = []
        buildHexData()
        buildParameters()
        tableView.reloadData()
    }

    private func buildParameters() {
        if let params = dataDecoded?.parameters {
            for parameter in params {
                headerCell("\(parameter.name)(\(parameter.type)):")
                buildValue(parameter.value)
            }
        } else {
            textCell("No parameters")
        }
    }

    private func buildHexData() {
        if let data = data {
            headerCell("Data")
            expandableCell("\(data.data.count) bytes") { [weak self] index in
                guard let `self` = self else { return [] }
                return [self.hexCell(at: index, text: data.description)]
            }
        }
    }

    private func hexCell(at index: Int, text: String) -> ActionDetailTextCell {
        let cell = self.tableView.dequeueCell(ActionDetailTextCell.self, for: IndexPath(row: index, section: 0))
        cell.setText(text, style: .body)
        cell.onTap = {
            Self.copyValue(text)
        }
        return cell
    }

    static func copyValue(_ value: String) {
        Pasteboard.string = value
        App.shared.snackbar.show(message: "Copied to clipboard", duration: 2)

    }

    static let indentWidth: CGFloat = 8.0

    /// Creates appropriate cell for each value type, including array
    /// for which it recursively builds the contents.
    ///
    /// - Parameters:
    ///   - paramValue: parameter value
    ///   - nestingLevel: current nesting level - influences the building
    ///    decisions and indentation level
    private func buildValue(_ paramValue: SCG.DataDecoded.Parameter.Value, nestingLevel: Int = 0) {
        let indentation: CGFloat = Self.indentWidth * CGFloat(nestingLevel)

        switch paramValue {

        case .string(let value):
            textCell(value, indentation: indentation)

        case .address(let value):
            addressCell(value.address, indentation: indentation)

        case .uint256(let value):
            textCell(value.description, indentation: indentation)

        case .data(let value):
            expandableCell("\(value.data.count) bytes", indentation: indentation) { [weak self] index in
                guard let `self` = self else { return [] }
                return [self.hexCell(at: index, text: value.description)]
            }

        case .array(let value):
                if nestingLevel == 0 {
                    // Initial contents are always visible.

                    if value.isEmpty {
                        emptyCell(indentation: indentation)
                    } else {
                        for item in value {
                            // recursion with incremented nesting level
                            buildValue(item, nestingLevel: nestingLevel + 1)
                        }
                    }

                } else {
                    // we're in recursive call.
                    // nested content is collapsed with indented "array" label

                    expandableCell("array", indentation: indentation) { [weak self] index in
                        guard let `self` = self else { return [] }
                        // this closure is called when the cell is expanded.

                        // We're going to re-use existing builder methods.
                        //
                        // So, in order not to mixup the current cell
                        // insertion index, we'll create new index,
                        // then build the cells that we need recursively
                        // and remove those cells from the output
                        // in order to return from this  closure.
                        //
                        // We'll restore the index after creating new cells.

                        let startIndex = self.pushIndex()

                        for item in value {
                            self.buildValue(item, nestingLevel: nestingLevel + 1)
                        }

                        let endIndex = self.popIndex()

                        // remove added cells because thye
                        let range = (startIndex..<endIndex)
                        let result = Array(self.cells[range])
                        self.cells.removeSubrange(range)

                        return result
                    }

                }
    case .unknown:
            textCell("Unknown value", indentation: indentation)
        }
    }

    // MARK: - Cell Builder Primitives

    /// Container for all cells in the table
    private var cells = [UITableViewCell]()

    /// Cells' index stack.
    ///
    /// The index will be popped during cell creation in builder methods.
    ///
    /// This allows to temporary change the insertion point of the cells
    /// and go back to previous insertion point
    /// by popping the pushed index.
    private var builderIndexStack = [0]


    /// Pushes the index to the top fo the index stack.
    /// - Parameter index: if nil, the `cells.count` will be used. Default is nil.
    /// - Returns: the new index that was just pushed.
    @discardableResult
    private func pushIndex(_ index: Int? = nil) -> Int {
        let nextIndex = index ?? cells.count
        builderIndexStack.append(index ?? cells.count)
        return nextIndex
    }

    /// Removes index from the top of the stack.
    /// - Returns: the index that was popped
    private func popIndex() -> Int {
        assert(!builderIndexStack.isEmpty)
        return builderIndexStack.removeLast()
    }

    private func headerCell(_ text: String, indentation: CGFloat = 0) {
        let cell = newCell(ActionDetailTextCell.self)
        cell.setText(text, style: GNOTextStyle(size: 16, weight: .bold, color: .gnoDarkBlue))
        cell.setIndentation(indentation)
        cell.selectionStyle = .none
    }

    private func textCell(_ text: String, indentation: CGFloat = 0) {
        let cell = newCell(ActionDetailTextCell.self)
        cell.setText(text, style: GNOTextStyle.body.color(.gnoDarkGrey))
        cell.setIndentation(indentation)
        cell.onTap = {
            Self.copyValue(text)
        }
    }

    private func emptyCell(indentation: CGFloat = 0) {
        let cell = newCell(ActionDetailTextCell.self)
        cell.setText("empty", style: GNOTextStyle.body.color(.gnoMediumGrey))
        cell.setIndentation(indentation)
        cell.selectionStyle = .none
    }

    private func addressCell(_ address: Address, indentation: CGFloat = 0) {
        let cell = newCell(ActionDetailAddressCell.self)
        cell.setAddress(address)
        cell.setIndentation(indentation)
        cell.selectionStyle = .none
    }

    /// Creates expandable cell that produces other cells when expanded.
    ///
    /// - Parameters:
    ///   - text: Text of the expandable header
    ///   - indentation: indentation width
    ///   - content: closure that produces new cells to insert right after
    ///     the expanded cell.
    private func expandableCell(_ text: String,
                                indentation: CGFloat = 0,
                                content: @escaping (Int) -> [UITableViewCell] = { _ in [] }) {
        let cell = newCell(ActionDetailExpandableCell.self)
        cell.setText(text)
        cell.state = .collapsed
        cell.setIndentation(indentation)

        cell.onTap = { [weak self, weak cell] in
            guard let `self` = self, let cell = cell, let cellIndex = self.cells.firstIndex(of: cell) else { return }

            switch cell.state {
            case .collapsed:
                // then expand the contents

                cell.state = .expanded

                // create cells
                let insertionIndex = cellIndex.advanced(by: 1)
                let insertedCells = content(insertionIndex)
                cell.subcells = insertedCells

                // update data source
                self.cells.insert(contentsOf: insertedCells, at: insertionIndex)

                // update UI
                self.tableView.beginUpdates()
                let insertedPaths = (insertionIndex..<insertionIndex.advanced(by: insertedCells.count)).map { IndexPath(row: $0, section: 0) }
                self.tableView.insertRows(at: insertedPaths, with: .bottom)
                self.tableView.endUpdates()

            case .expanded:
                // then collapse the contents

                cell.state = .collapsed

                // remember indexes of removed cells and remove them
                var deletedPaths = [IndexPath]()
                deletedPaths = cell.subcells
                    .compactMap { self.cells.firstIndex(of: $0) }
                    .map { IndexPath(row: $0, section: 0) }

                cell.subcells = []

                // update data source
                for path in deletedPaths {
                    self.cells.remove(at: path.row)
                }

                // update UI
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: deletedPaths, with: .top)
                self.tableView.endUpdates()

            }

        }
    }

    /// Creates new cell in the table view at the index from the top of the
    /// stack and increments the top index.
    ///
    /// - Parameter cls: class to use for the identifier
    /// - Returns: newly created or reused cell
    private func newCell<T: UITableViewCell>(_ cls: T.Type) -> T {
        let index = popIndex()
        defer { pushIndex(index + 1) }

        let indexPath = IndexPath(row: index, section: 0)
        let cell = tableView.dequeueCell(cls, for: indexPath)
        cells.insert(cell, at: index)
        return cell
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? ActionDetailTableViewCell {
            cell.onTap()
        }
    }
}
