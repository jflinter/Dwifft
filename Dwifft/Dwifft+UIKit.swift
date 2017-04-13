//
//  Dwifft+UIKit.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

// TODO document all of me please
// TODO update readme please

#if os(iOS)

import UIKit

class AbstractDiffCalculator<Section: Equatable, Value: Equatable> {

    fileprivate init(initialRowsAndSections: SectionedValues<Section, Value>) {
        self._rowsAndSections = initialRowsAndSections
    }

    public final func numberOfSections() -> Int {
        return self.rowsAndSections.count
    }

    public final func value(forSection: Int) -> Section {
        return self.rowsAndSections[forSection].0
    }

    public final func numberOfObjects(inSection section: Int) -> Int {
        return self.rowsAndSections[section].1.count
    }

    public final func value(atIndexPath indexPath: IndexPath) -> Value {
        return self.rowsAndSections[indexPath.section].1[indexPath.row]
    }

    public final var rowsAndSections: SectionedValues<Section, Value> {
        get {
            return _rowsAndSections
        }
        set {
            let oldRowsAndSections = rowsAndSections
            let newRowsAndSections = newValue
            let diff = Dwifft.diff(lhs: oldRowsAndSections, rhs: newRowsAndSections)
            if (diff.count > 0) {
                self.processChanges(newState: newRowsAndSections, diff: diff)
            }
        }
    }

    // UITableView and UICollectionView both perform assertions on the *current* number of rows/items before performing any updates. As such, the `rowsAndSections` property must be backed by an internal value that does not change until *after* `beginUpdates`/`performBatchUpdates` has been called.
    fileprivate final var _rowsAndSections: SectionedValues<Section, Value>
    fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]){
        fatalError("override me")
    }
}

public final class TableViewDiffCalculator<Section: Equatable, Value: Equatable>: AbstractDiffCalculator<Section, Value> {

    public weak var tableView: UITableView?

    public init(tableView: UITableView?, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.tableView = tableView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    override public func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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

public final class CollectionViewDiffCalculator<Section: Equatable, Value: Equatable> : AbstractDiffCalculator<Section, Value> {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView?, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.collectionView = collectionView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    override func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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

public final class SingleSectionTableViewDiffCalculator<Value: Equatable> {

    public weak var tableView: UITableView?
    public let sectionIndex: Int
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic
    public var rows : [Value] {
        get {
            return self.internalDiffCalculator.rowsAndSections[self.sectionIndex].1
        }
        set {
            self.internalDiffCalculator.rowsAndSections = SingleSectionTableViewDiffCalculator.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
        }
    }

    public init(tableView: UITableView?, initialRows: [Value] = [], sectionIndex: Int = 0) {
        self.tableView = tableView
        self.internalDiffCalculator = TableViewDiffCalculator(tableView: tableView, initialRowsAndSections: SingleSectionTableViewDiffCalculator.buildSectionedValues(values: initialRows, sectionIndex: sectionIndex))
        self.sectionIndex = sectionIndex
    }

    fileprivate static func buildSectionedValues(values: [Value], sectionIndex: Int) -> SectionedValues<Int, Value> {
        let firstRows = (0..<sectionIndex).map { ($0, [Value]()) }
        return SectionedValues(firstRows + [(sectionIndex, values)])
    }

    private let internalDiffCalculator: TableViewDiffCalculator<Int, Value>

}

public final class SingleSectionCollectionViewDiffCalculator<Value: Equatable> {

    public weak var collectionView: UICollectionView?
    public let sectionIndex: Int
    public var items : [Value] {
        get {
            return self.internalDiffCalculator.rowsAndSections[self.sectionIndex].1
        }
        set {
            self.internalDiffCalculator.rowsAndSections = SingleSectionTableViewDiffCalculator.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
        }
    }

    public init(collectionView: UICollectionView?, initialItems: [Value] = [], sectionIndex: Int = 0) {
        self.collectionView = collectionView
        self.internalDiffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialRowsAndSections: SingleSectionTableViewDiffCalculator.buildSectionedValues(values: initialItems, sectionIndex: sectionIndex))
        self.sectionIndex = sectionIndex
    }

    private let internalDiffCalculator: CollectionViewDiffCalculator<Int, Value>
    
}

#endif
