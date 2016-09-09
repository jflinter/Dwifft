//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

#if os(iOS)

import UIKit

open class TableViewDiffCalculator<T: Equatable> {
    
    open weak var tableView: UITableView?
    
    public init(tableView: UITableView, initialRows: [T] = []) {
        self.tableView = tableView
        self.rows = initialRows
    }
    
    /// Right now this only works on a single section of a tableView. If your tableView has multiple sections, though, you can just use multiple TableViewDiffCalculators, one per section, and set this value appropriately on each one.
    open var sectionIndex: Int = 0
    
    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    open var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic
    
    /// Change this value to trigger animations on the table view.
    open var rows : [T] {
        didSet {
            
            let oldRows = oldValue
            let newRows = self.rows
            let diff = oldRows.diff(newRows)
            if (diff.results.count > 0) {
                tableView?.beginUpdates()
                
                let insertionIndexPaths = diff.insertions.map({ IndexPath(row: $0.idx, section: self.sectionIndex) })
                let deletionIndexPaths = diff.deletions.map({ IndexPath(row: $0.idx, section: self.sectionIndex) })
                
                tableView?.insertRows(at: insertionIndexPaths, with: insertionAnimation)
                tableView?.deleteRows(at: deletionIndexPaths, with: deletionAnimation)
                
                tableView?.endUpdates()
            }
            
        }
    }
    
}
    
open class CollectionViewDiffCalculator<T: Equatable> {
    
    open weak var collectionView: UICollectionView?
    
    public init(collectionView: UICollectionView, initialRows: [T] = []) {
        self.collectionView = collectionView
        self.rows = initialRows
    }
    
    /// Right now this only works on a single section of a collectionView. If your collectionView has multiple sections, though, you can just use multiple CollectionViewDiffCalculators, one per section, and set this value appropriately on each one.
    open var sectionIndex: Int = 0
    
    /// Change this value to trigger animations on the collection view.
    open var rows : [T] {
        didSet {
            
            let oldRows = oldValue
            let newRows = self.rows
            let diff = oldRows.diff(newRows)
            if (diff.results.count > 0) {
                let insertionIndexPaths = diff.insertions.map({ IndexPath(item: $0.idx, section: self.sectionIndex) })
                let deletionIndexPaths = diff.deletions.map({ IndexPath(item: $0.idx, section: self.sectionIndex) })
                
                collectionView?.performBatchUpdates({ () -> Void in
                    self.collectionView?.insertItems(at: insertionIndexPaths)
                    self.collectionView?.deleteItems(at: deletionIndexPaths)
                }, completion: nil)
            }
            
        }
    }
    
}

#endif
