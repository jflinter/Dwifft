//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

#if os(iOS)

import UIKit

public class TableViewDiffCalculator<T: Equatable> {
    
    public weak var tableView: UITableView?

    public init(tableView: UITableView, initialRows: [[T]] = []) {
        self.tableView = tableView
        self._rows = initialRows
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    public func numberOfSections() -> Int {
        return self.rows.count
    }

    public func numberOfRows(inSection section: Int) -> Int {
        return self.rows[section].count
    }

    public func value(atIndexPath indexPath: IndexPath) -> T {
        return self.rows[indexPath.section][indexPath.row]
    }

    /// Change this value to trigger animations on the table view.
    private var _rows: [[T]]
    public var rows : [[T]] {
        get {
            return _rows
        }
        set {
            let oldRows = rows
            let newRows = newValue
            let diff = ArrayDiff2D(lhs: oldRows, rhs: newRows)
            if (diff.results.count > 0) {
                tableView?.beginUpdates()
                self._rows = newValue
                for result in diff.results {
                    switch result {
                    case .sectionInsert(let sectionIndex):
                        self.tableView?.insertSections(IndexSet(integer: sectionIndex), with: self.insertionAnimation)
                    case .sectionDelete(let sectionIndex):
                        self.tableView?.deleteSections(IndexSet(integer: sectionIndex), with: self.deletionAnimation)
                    case .insert(let sectionIndex, let rowIndex, _):
                        self.tableView?.insertRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: self.insertionAnimation)
                    case .delete(let sectionIndex, let rowIndex, _):
                        self.tableView?.deleteRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: self.deletionAnimation)
                    }
                }
                tableView?.endUpdates()
            }
        }
    }
    
}
    
public class CollectionViewDiffCalculator<T: Equatable> {
    
    public weak var collectionView: UICollectionView?
    
    public init(collectionView: UICollectionView, initialRows: [[T]] = []) {
        self.collectionView = collectionView
        _rows = initialRows
    }

    public func numberOfSections() -> Int {
        return self.rows.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return self.rows[section].count
    }

    public func value(atIndexPath indexPath: IndexPath) -> T {
        return self.rows[indexPath.section][indexPath.item]
    }

    // Since UICollectionView (unlike UITableView) takes a block which must update its data source and trigger animations, we need to trigger the changes on set, instead of explicitly before and after set. This backing array lets us use a getter/setter in the exposed property.
    private var _rows: [[T]]

    /// Change this value to trigger animations on the collection view.
    public var rows : [[T]] {
        get {
            return _rows
        }
        set {
            let oldRows = rows
            let newRows = newValue
            let diff = ArrayDiff2D(lhs: oldRows, rhs: newRows)
            if (diff.results.count > 0) {
                collectionView?.performBatchUpdates({ () -> Void in
                    self._rows = newValue

                    for result in diff.results {
                        switch result {
                        case .sectionInsert(let sectionIndex):
                            self.collectionView?.insertSections(IndexSet(integer: sectionIndex))
                        case .sectionDelete(let sectionIndex):
                            self.collectionView?.deleteSections(IndexSet(integer: sectionIndex))
                        case .insert(let sectionIndex, let rowIndex, _):
                            self.collectionView?.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
                        case .delete(let sectionIndex, let rowIndex, _):
                            self.collectionView?.deleteItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
                        }
                    }
                }, completion: nil)
            }
            
        }
    }
    
}

#endif
