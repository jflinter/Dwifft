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

class StuffCollectionViewCell: UICollectionViewCell {
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

class StuffCollectionViewController: UICollectionViewController {

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(StuffCollectionViewController.shuffle))
    }

    @objc func shuffle() {
        self.stuff = Stuff.emojiStuff()
    }

    var stuff: SectionedValues<AnyHashable, AnyHashable> = Stuff.emojiStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.sections = stuff
        }
    }

    var diffCalculator: CollectionViewDiffCalculator?

    override func viewDidLoad() {
        // TODO make me slightly prettier
        super.viewDidLoad()
        guard let collectionView = self.collectionView else { return }
        self.diffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialSections: self.stuff)

        // Register cell classes
        self.collectionView!.register(StuffCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.diffCalculator?.numberOfSections() ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.diffCalculator?.numberOfObjects(inSection: section) ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! StuffCollectionViewCell
        guard let diffCalculator = self.diffCalculator else { return cell }
        if let thing = diffCalculator.value(atIndexPath: indexPath) as? String {
            cell.label.text = thing
        }
        return cell
    }

}
