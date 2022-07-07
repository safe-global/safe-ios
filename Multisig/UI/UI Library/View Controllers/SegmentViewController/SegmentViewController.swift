//
//  SegmentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class SegmentViewController: ContainerViewController {
    @IBOutlet private weak var segmentBar: UIView!
    @IBOutlet private weak var segmentBarStackView: UIStackView!
    @IBOutlet private weak var contentView: UIView!

    var segmentItems = [SegmentBarItem]()
    var selectedIndex: Int?

    private var segmentViews = [SegmentView]()

    // preconditions
    //      view controllers are added
    //      segmentItems are set
    //      number of segmentItems is same as number of view controllers
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentViews = segmentItems.enumerated().map { index, item in
            let s = SegmentView()
            s.index = index

            s.setImage(item.image)
            s.setTitle(item.title.uppercased())

            s.isSelected = false
            s.onTap = { [weak self] index in
                self?.didTapSegmentView(at: index)
            }
            return s
        }
        segmentViews.forEach { v in
            segmentBarStackView.addArrangedSubview(v)
        }

        if segmentItems.isEmpty {
            segmentBar.isHidden = true
        } else {
            selectSegment(at: selectedIndex)
        }
    }

    private func didTapSegmentView(at index: Int) {
        selectSegment(at: index)
    }

    // select segment programmatically by index
    //  preconditions
    //      index is in bounds of segmentItems or nil
    func selectSegment(at index: Int?) {
        guard let newIndex = index else {
            deselectAllSegments()
            selectedIndex = nil
            return
        }
        selectedIndex = index
        guard !segmentViews.isEmpty else { return }
        let newSelectedSegment = segmentViews[newIndex]
        newSelectedSegment.isSelected = true
        //     deselect other views
        segmentViews.filter { $0 !== newSelectedSegment }.forEach {
            $0.isSelected = false
        }
        displayChild(at: newIndex, in: contentView)
    }

    func deselectAllSegments() {
        segmentViews.forEach {
            $0.isSelected = false
        }
    }

}

struct SegmentBarItem {
    var image: UIImage?
    var title: String
}
