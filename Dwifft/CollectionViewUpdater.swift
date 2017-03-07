//
//  CollectionViewUpdater.swift
//  Dwifft
//
//  Created by Sid on 07/03/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit

public class CollectionViewUpdater: DiffableViewUpdater {

    weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    public func perform(operations: ViewOperationsType, animated: Bool, completion: @escaping () -> Void) {
        guard animated else {
            completion()
            collectionView?.reloadData()
            return
        }

        collectionView?.performBatchUpdates({
            self.collectionView?.insertItems(at: operations.insertionIndexPaths)
            self.collectionView?.deleteItems(at: operations.deletionIndexPaths)
            completion()
        }, completion: nil)
    }
}
