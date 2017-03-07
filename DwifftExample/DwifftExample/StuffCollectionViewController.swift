//
//  StuffCollectionViewController.swift
//  DwifftExample
//
//  Created by Sid on 07/03/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit
import Dwifft

class StuffCollectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var headerLabel: UILabel!

}

class StuffCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .black
            titleLabel.numberOfLines = 0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class StuffCollectionViewController: UICollectionViewController {

    fileprivate lazy var dataSource: StuffDataSouce = {
        return StuffDataSouce(
            sections: 2,
            viewUpdater: CollectionViewUpdater(
                collectionView: self.collectionView!
            )
        )
    }()

    @objc func onShuffle() {
        dataSource.shuffle(animated: true)
    }

    @objc func onDismiss() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(onShuffle))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onDismiss))

        dataSource.shuffle(animated: false)
    }

    // MARK: - Collection view data souce
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfStuff(in: section)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfStuffs
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuseIdentifier", for: indexPath)
        if let stuffCell = cell as? StuffCollectionViewCell {
            stuffCell.titleLabel?.text = dataSource.stuff(section: indexPath.section, row: indexPath.item)
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerReuseIdentifier", for: indexPath)
        if let stuffHeaderView = headerView as? StuffCollectionHeaderView {
            stuffHeaderView.headerLabel.text = "Section: \(indexPath.section)"
        }
        return headerView
    }
}
