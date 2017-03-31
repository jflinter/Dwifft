//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

#if os(iOS)

import UIKit

public protocol DiffCalculator: class {
    associatedtype S: Equatable
    associatedtype T: Equatable
    var rowsAndSections: SectionedValues<S, T> { get set }
    func numberOfSections() -> Int
    func value(forSection: Int) -> S
    func numberOfObjects(inSection section: Int) -> Int
    func value(atIndexPath indexPath: IndexPath) -> T

    func processChanges(
        newState: SectionedValues<S, T>,
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        deletionIndexPaths: [IndexPath],
        insertionIndexPaths: [IndexPath]
    )

    func internalRowsAndSections() -> SectionedValues<S, T>
}

public extension DiffCalculator {
    public func numberOfSections() -> Int {
        return self.rowsAndSections.count
    }

    public func value(forSection: Int) -> S {
        return self.rowsAndSections[forSection].0
    }

    public func numberOfObjects(inSection section: Int) -> Int {
        return self.rowsAndSections[section].1.count
    }

    public func value(atIndexPath indexPath: IndexPath) -> T {
        return self.rowsAndSections[indexPath.section].1[indexPath.row]
    }

    public var rowsAndSections : SectionedValues<S, T> {
        get {
            return internalRowsAndSections()
        }
        set {
            let oldRowsAndSections = rowsAndSections
            let newRowsAndSections = newValue
            var wip = oldRowsAndSections
            let diff = Diff2D.diff(lhs: oldRowsAndSections, rhs: newRowsAndSections)
            if (diff.results.count > 0) {

                // we need to do a 2-pass update to the tableview here due to what appears to be a bug in UITableView.
                // it does not handle calling `deleteSections` and `deleteRows` inside the same `beginUpdates/endUpdates` block
                // nicely - it will not actually track the section indices correctly. For example, if the tableview looks like
                // ["a": [], "b": [2, 3]], and transitions to ["b": [2]], it will expect a call to `deleteRows` with (1, 1)
                // even after you've already deleted section 0 (the correct thing to expect would be (0, 0).

                // TODO can we pause UIKit updates somehow to mitigate this
                for sectionDeletion in diff.sectionDeletions {
                    wip.applyStep(step: sectionDeletion)
                }
                for sectionInsertion in diff.sectionInsertions {
                    wip.applyStep(step: sectionInsertion)
                }
                let sectionDeletionIndices: IndexSet = diff.sectionDeletions.reduce(IndexSet()) { accum, d in
                    var next = accum
                    next.insert(d.section)
                    return next
                }
                let sectionInsertionIndices: IndexSet = diff.sectionInsertions.reduce(IndexSet()) { accum, d in
                    var next = accum
                    next.insert(d.section)
                    return next
                }

                self.processChanges(
                    newState: wip,
                    sectionDeletionIndices: sectionDeletionIndices,
                    sectionInsertionIndices: sectionInsertionIndices,
                    deletionIndexPaths: [],
                    insertionIndexPaths: []
                )

                let deletionIndexPaths: [IndexPath] = diff.deletions.flatMap { d in
                    guard let row = d.row else { return nil }
                    return IndexPath(row: row, section: d.section)
                }
                let insertionIndexPaths: [IndexPath] = diff.insertions.flatMap { d in
                    guard let row = d.row else { return nil }
                    return IndexPath(row: row, section: d.section)
                }

                self.processChanges(
                    newState: newRowsAndSections,
                    sectionDeletionIndices: IndexSet(),
                    sectionInsertionIndices: IndexSet(),
                    deletionIndexPaths: deletionIndexPaths,
                    insertionIndexPaths: insertionIndexPaths
                )
                
            }
        }
    }

}

public class TableViewDiffCalculator<S: Equatable, T: Equatable>: DiffCalculator {

    public weak var tableView: UITableView?

    private var _rowsAndSections: SectionedValues<S, T>

    public init(tableView: UITableView, initialRowsAndSections: SectionedValues<S, T> = SectionedValues()) {
        self.tableView = tableView
        self._rowsAndSections = initialRowsAndSections
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    public func internalRowsAndSections() -> SectionedValues<S, T> {
        return self._rowsAndSections
    }

    public func processChanges(
        newState: SectionedValues<S, T>,
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        deletionIndexPaths: [IndexPath],
        insertionIndexPaths: [IndexPath]
    ) {
        guard let tableView = self.tableView else { return }
        tableView.beginUpdates()
        self._rowsAndSections = newState
        tableView.deleteSections(sectionDeletionIndices, with: self.deletionAnimation)
        tableView.insertSections(sectionInsertionIndices, with: self.insertionAnimation)
        tableView.deleteRows(at: deletionIndexPaths, with: self.deletionAnimation)
        tableView.insertRows(at: insertionIndexPaths, with: self.insertionAnimation)
        tableView.endUpdates()
    }
}

public class CollectionViewDiffCalculator<S: Equatable, T: Equatable> : DiffCalculator {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView, initialRowsAndSections: SectionedValues<S, T> = SectionedValues()) {
        self.collectionView = collectionView
        _rowsAndSections = initialRowsAndSections
    }

    // Since UICollectionView (unlike UITableView) takes a block which must update its data source and trigger animations, we need to trigger the changes on set, instead of explicitly before and after set. This backing array lets us use a getter/setter in the exposed property.
    private var _rowsAndSections: SectionedValues<S, T>
    public func internalRowsAndSections() -> SectionedValues<S, T> {
        return self._rowsAndSections
    }

    public func processChanges(
        newState: SectionedValues<S, T>,
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        deletionIndexPaths: [IndexPath],
        insertionIndexPaths: [IndexPath]
    ) {
        guard let collectionView = self.collectionView else { return }
        collectionView.performBatchUpdates({ () -> Void in
            self._rowsAndSections = newState
            collectionView.deleteSections(sectionDeletionIndices)
            collectionView.insertSections(sectionInsertionIndices)
            collectionView.deleteItems(at: deletionIndexPaths)
            collectionView.insertItems(at: insertionIndexPaths)
        }, completion: nil)
    }

}

#endif
