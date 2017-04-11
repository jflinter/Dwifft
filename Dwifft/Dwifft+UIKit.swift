//
//  Dwifft+UIKit.swift
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
        diff: [DiffStep2D<S, T>]
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
            let diff = Diff2D.diff(lhs: oldRowsAndSections, rhs: newRowsAndSections)
            if (diff.results.count > 0) {
                self.processChanges(newState: newRowsAndSections, diff: diff.results)
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

    public func processChanges(newState: SectionedValues<S, T>, diff: [DiffStep2D<S, T>]) {
        guard let tableView = self.tableView else { return }
        tableView.beginUpdates()
        self._rowsAndSections = newState
        for result in diff {
            switch result {
            case let .delete(section, row, _): tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: self.deletionAnimation)
            case let .insert(section, row, _): tableView.insertRows(at: [IndexPath(row: row, section: section)], with: self.insertionAnimation)
            case let .sectionDelete(section, _): tableView.deleteSections(IndexSet(integer: section), with: self.deletionAnimation)
            case let .sectionInsert(section, _): tableView.insertSections(IndexSet(integer: section), with: self.insertionAnimation)
            }
        }
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

    public func processChanges(newState: SectionedValues<S, T>, diff: [DiffStep2D<S, T>]) {
        guard let collectionView = self.collectionView else { return }
        self._rowsAndSections = newState
        collectionView.performBatchUpdates({
            self._rowsAndSections = newState
            for result in diff {
                switch result {
                case let .delete(section, row, _): collectionView.deleteItems(at: [IndexPath(row: row, section: section)])
                case let .insert(section, row, _): collectionView.insertItems(at: [IndexPath(row: row, section: section)])
                case let .sectionDelete(section, _): collectionView.deleteSections(IndexSet(integer: section))
                case let .sectionInsert(section, _): collectionView.insertSections(IndexSet(integer: section))
                }
            }
        }, completion: nil)
    }
}

typealias SimpleTableViewDiffCalculator = TableViewDiffCalculator<AnyHashable, AnyHashable>
typealias SimpleCollectionViewDiffCalculator = CollectionViewDiffCalculator<AnyHashable, AnyHashable>

#endif
