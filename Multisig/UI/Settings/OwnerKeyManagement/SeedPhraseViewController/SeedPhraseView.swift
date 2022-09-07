//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SeedPhraseView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    weak var collectionView: UICollectionView!
    weak var collectionViewLayout: UICollectionViewFlowLayout!
    var heightConstraint: NSLayoutConstraint!
    var metrics = CellMetrics()
    let collectionInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)

    var words: [SeedWord] = [] {
        didSet {
            didUpdateWords()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    func didUpdateWords() {
        assert(words.enumerated().allSatisfy { $0.element.index == $0.offset }, "Incorrect word index")
        update()
        collectionView.reloadData()
    }

    func commonInit() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)

        collectionViewLayout.scrollDirection = .horizontal

        let nib = UINib(nibName: "SeedWordCollectionViewCell", bundle: Bundle(for: SeedWordCollectionViewCell.self))
        collectionView.register(nib, forCellWithReuseIdentifier: "SeedWordCollectionViewCell")

        collectionView.allowsSelection = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.clipsToBounds = false
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear

        self.backgroundColor = .backgroundSecondary
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 8

        addSubview(collectionView)

        wrapAroundView(collectionView, insets: collectionInset)

        let borderView = UIView()
        borderView.backgroundColor = .separator
        borderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(borderView)
        self.addConstraints([
            borderView.topAnchor.constraint(equalTo: self.topAnchor),
            borderView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            borderView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            borderView.widthAnchor.constraint(equalToConstant: 2)
        ])

        self.collectionView = collectionView
        self.collectionViewLayout = collectionViewLayout

        heightConstraint = heightAnchor.constraint(equalToConstant: 240) // this will be changed during update()
        heightConstraint.isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderColor = UIColor.separator.cgColor
    }

    func update() {
        metrics.calculate(basedOn: collectionView)

        heightConstraint.constant = metrics.totalHeight(itemCount: words.count) + collectionInset.top + collectionInset.bottom
        setNeedsUpdateConstraints()

        collectionViewLayout.itemSize = metrics.size
        collectionViewLayout.minimumInteritemSpacing = metrics.hSpace
        collectionViewLayout.minimumLineSpacing = metrics.vSpace

        collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        words.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < words.count else { return UICollectionViewCell() }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SeedWordCollectionViewCell",
                                                      for: indexPath) as! SeedWordCollectionViewCell
        cell.word = words[indexPath.item]
        // for unknown reason the bounds X is -8, this fixes it.
        cell.bounds.origin = .zero
        return cell
    }
}

extension SeedPhraseView {
    struct CellMetrics {
        var size: CGSize = CGSize(width: 88, height: 34)
        var hSpace: CGFloat = 0
        var vSpace: CGFloat = 2
        var columnCount: Int = 2

        mutating func calculate(basedOn container: UIView) {
            if columnCount == 0 { return }
            size.width = floor((container.frame.width - CGFloat(columnCount - 1) * hSpace) / CGFloat(columnCount))
        }

        func totalHeight(itemCount: Int) -> CGFloat {
            if itemCount == 0 || columnCount == 0 { return 0 }
            let rowCount = ceil(CGFloat(itemCount) / CGFloat(columnCount))
            return rowCount * size.height + (rowCount - 1) * vSpace
        }

    }
}
