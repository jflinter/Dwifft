//
//  Dwifft+UIKit.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

#if os(iOS)

import UIKit

class AbstractDiffCalculator<Section: Equatable, Value: Equatable> {

    init(initialRowsAndSections: SectionedValues<Section, Value>) {
        self._rowsAndSections = initialRowsAndSections
    }

    public func numberOfSections() -> Int {
        return self.rowsAndSections.count
    }

    public func value(forSection: Int) -> Section {
        return self.rowsAndSections[forSection].0
    }

    public func numberOfObjects(inSection section: Int) -> Int {
        return self.rowsAndSections[section].1.count
    }

    public func value(atIndexPath indexPath: IndexPath) -> Value {
        return self.rowsAndSections[indexPath.section].1[indexPath.row]
    }

    // Since UICollectionView (unlike UITableView) takes a block which must update its data source and trigger animations, we need to trigger the changes on set, instead of explicitly before and after set. This backing array lets us use a getter/setter in the exposed property. TODO
    public var rowsAndSections : SectionedValues<Section, Value> {
        get {
            return _rowsAndSections
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


    fileprivate var _rowsAndSections: SectionedValues<Section, Value>
    fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [DiffStep2D<Section, Value>]){
        fatalError("override me")
    }
}

public class TableViewDiffCalculator<Section: Equatable, Value: Equatable>: AbstractDiffCalculator<Section, Value> {

    public weak var tableView: UITableView?

    public init(tableView: UITableView, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.tableView = tableView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    override public func processChanges(newState: SectionedValues<Section, Value>, diff: [DiffStep2D<Section, Value>]) {
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

public class CollectionViewDiffCalculator<Section: Equatable, Value: Equatable> : AbstractDiffCalculator<Section, Value> {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.collectionView = collectionView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    override func processChanges(newState: SectionedValues<Section, Value>, diff: [DiffStep2D<Section, Value>]) {
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
