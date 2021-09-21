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
        reloadSegmentBar()

        if segmentItems.isEmpty {
            segmentBar.isHidden = true
        } else {
            selectSegment(at: selectedIndex)
        }
    }

    private func didTapSegmentView(at index: Int) {
        selectSegment(at: index)
    }

    func reloadSegmentBar() {
        for v in segmentViews {
            segmentBarStackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }

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

        let shouldShow = segmentBar.isHidden && !segmentViews.isEmpty

        if shouldShow {
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self = self else { return }
                self.segmentBar.isHidden = self.segmentItems.isEmpty
            }
        } else {
            self.segmentBar.isHidden = self.segmentItems.isEmpty
        }
    }

    // select segment programmatically by index
    //      this will select the segment in the segment bar (if such segment at index exist)
    //      and will display the child view controller at the index (if such child exist)
    func selectSegment(at index: Int?) {
        guard let newIndex = index else {
            deselectAllSegments()
            selectedIndex = nil
            return
        }
        selectedIndex = index

        if segmentViews.indices.contains(newIndex) {
            let newSelectedSegment = segmentViews[newIndex]
            newSelectedSegment.isSelected = true
            //     deselect other views
            segmentViews.filter { $0 !== newSelectedSegment }.forEach {
                $0.isSelected = false
            }
        }

        if let container = contentView {
            displayChild(at: newIndex, in: container)
        }
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
