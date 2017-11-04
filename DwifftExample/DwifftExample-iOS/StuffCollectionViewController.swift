//
//  StuffCollectionViewController.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit
import Dwifft

private let reuseIdentifier = "Cell"
private let headerReuseIdentifier = "Header"

final class StuffCollectionViewCell: UICollectionViewCell {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.bounds
    }
}

final class StuffSectionHeaderView: UICollectionReusableView {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .left
        label.font = UIFont.italicSystemFont(ofSize: 14)
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = self.bounds.insetBy(dx: 10, dy: 0)
    }
}

final class StuffCollectionViewController: UICollectionViewController {

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(StuffCollectionViewController.shuffle))
    }

    @objc func shuffle() {
        self.stuff = Stuff.emojiStuff()
    }

    var stuff: SectionedValues<String, String> = Stuff.emojiStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.sectionedValues = stuff
        }
    }

    var diffCalculator: CollectionViewDiffCalculator<String, String>?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = self.collectionView else { return }
        self.diffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialSectionedValues: self.stuff)

        // Register cell classes
        collectionView.register(StuffCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(
            StuffSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
            withReuseIdentifier: headerReuseIdentifier
        )
    }

    // MARK: UICollectionViewDataSource

    /// IMPORTANT: you *must* implement `numberOfSections` this way (meaning, using this function on your diff calculator) in your app, to avoid a lot of gotchas around UICollectionView's internal assertions.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let diffCalculator = diffCalculator else { return 0 }
        return diffCalculator.numberOfSections()
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! StuffSectionHeaderView
        header.label.text = diffCalculator?.value(forSection: indexPath.section)
        return header
    }

    /// IMPORTANT: you *must* implement `numberOfItemsInSection` this way (meaning, using this function on your diff calculator) in your app, to avoid a lot of gotchas around UICollectionView's internal assertions.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let diffCalculator = self.diffCalculator else { return 0 }
        return diffCalculator.numberOfObjects(inSection: section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! StuffCollectionViewCell
        guard let diffCalculator = self.diffCalculator else { return cell }
        let thing = diffCalculator.value(atIndexPath: indexPath)
        cell.label.text = thing
        return cell
    }

}
