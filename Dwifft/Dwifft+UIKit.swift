//
//  Dwifft+UIKit.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

// TODO update readme please
// TODO jazzy

#if os(iOS)

import UIKit

internal class AbstractDiffCalculator<Section: Equatable, Value: Equatable> {

    fileprivate init(initialRowsAndSections: SectionedValues<Section, Value>) {
        self._rowsAndSections = initialRowsAndSections
    }

    /// The number of sections in the diff calculator. Return this inside
    /// `numberOfSections(in: tableView)` or `numberOfSections(in: collectionView)`.
    /// Don't implement that method any other way (see the docs for `numberOfObjects(inSection:)`
    /// for more context).
    public final func numberOfSections() -> Int {
        return self.rowsAndSections.count
    }

    /// The section at a given index. If you implement `tableView:titleForHeaderInSection` or
    /// `collectionView:viewForSupplementaryElementOfKind:atIndexPath`, you can use this
    /// method to get information about that section out of Dwifft.
    ///
    /// - Parameter forSection: the index of the section you care about.
    /// - Returns: the Section at that index.
    public final func value(forSection: Int) -> Section {
        return self.rowsAndSections[forSection].0
    }


    /// The, uh, number of objects in a given section. Use this to implement
    /// `UITableViewDataSource.numberOfRowsInSection:` or `UICollectionViewDataSource.numberOfItemsInSection:`.
    /// Seriously, don't implement that method any other way - there is some subtle timing stuff
    /// around when this value should change in order to satisfy `UITableView`/`UICollectionView`'s internal
    /// assertions, that Dwifft knows how to handle correctly. Read the source for
    /// Dwifft+UIKit.swift if you don't believe me/want to learn more.
    ///
    /// - Parameter section: a section of your table/collection view
    /// - Returns: the number of objects in that section.
    public final func numberOfObjects(inSection section: Int) -> Int {
        return self.rowsAndSections[section].1.count
    }


    /// The value at a given index path. Use this to implement
    /// `UITableViewDataSource.cellForRowAtIndexPath` or `UICollectionViewDataSource.cellForItemAtIndexPath`.
    ///
    /// - Parameter indexPath: the index path you are interested in
    /// - Returns: the thing at that index path
    public final func value(atIndexPath indexPath: IndexPath) -> Value {
        return self.rowsAndSections[indexPath.section].1[indexPath.row]
    }


    /// Set this variable to automatically trigger the correct section/row/item insertion/deletions
    /// on your table/collection view. TODO maybe rename?
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


/// This class manages a `UITableView`'s rows and sections. It will make the necessary calls to
/// the table view to ensure that its UI is kept in sync with the contents of the `rowsAndSections` property.
public final class TableViewDiffCalculator<Section: Equatable, Value: Equatable>: AbstractDiffCalculator<Section, Value> {

    public weak var tableView: UITableView?

    public init(tableView: UITableView?, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.tableView = tableView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    /// You can change insertion/deletion animations like this! Fade works well.
    /// So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    override fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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

/// This class manages a `UICollectionView`'s items and sections. It will make the necessary
/// calls to the collection view to ensure that its UI is kept in sync with the contents 
/// of the `rowsAndSections` property.
public final class CollectionViewDiffCalculator<Section: Equatable, Value: Equatable> : AbstractDiffCalculator<Section, Value> {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView?, initialRowsAndSections: SectionedValues<Section, Value> = SectionedValues()) {
        self.collectionView = collectionView
        super.init(initialRowsAndSections: initialRowsAndSections)
    }

    override fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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

/// Let's say your data model consists of different sections containing different model types. Since
/// `SectionedValues` requires a uniform type for all of its rows, this can be a clunky situation. You
/// can address this in a couple of ways. The first is to define a custom enum that encompasses all of the
/// things that *could* be in your data model - if section 1 has a bunch of `String`s, and section 2 has a bunch
/// of `Int`s, define a `StringOrInt` enum that conforms to `Equatable`, and fill the `SectionedValues`
/// that you use to drive your DiffCalculator up with those. Alternatively, if you are lazy, and your
/// models all conform to `Hashable`, you can use a SimpleTableViewDiffCalculator instead.
typealias SimpleTableViewDiffCalculator = TableViewDiffCalculator<AnyHashable, AnyHashable>

/// See SimpleTableViewDiffCalculator for explanation
typealias SimpleCollectionViewDiffCalculator = CollectionViewDiffCalculator<AnyHashable, AnyHashable>

/// If your table view only has a single section, or you only want to power a single section of it with Dwifft,
/// use a `SingleSectionTableViewDiffCalculator`. Note that this approach is not highly recommended, and you should
/// do so only if it *really* doesn't make sense to just power your whole table with a `TableViewDiffCalculator`.
/// You'll be less likely to mess up the index math 😬
public final class SingleSectionTableViewDiffCalculator<Value: Equatable> {

    public weak var tableView: UITableView?

    /// All insertion/deletion calls will be made on this index.
    public let sectionIndex: Int

    /// You can change insertion/deletion animations like this! Fade works well.
    /// So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    public func numberOfRows(inSection section: Int) -> Int {
        guard section == self.sectionIndex else {
            fatalError("trying to get the number of items for a section that isn't yours!")
        }
        return rows.count
    }

    /// Set this variable to automatically trigger the correct row insertion/deletions
    /// on your table view.
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

/// If your collection view only has a single section, or you only want to power a single section of it with Dwifft,
/// use a `SingleSectionCollectionViewDiffCalculator`. Note that this approach is not highly recommended, and you should
/// do so only if it *really* doesn't make sense to just power your whole view with a `CollectionViewDiffCalculator`.
/// You'll be less likely to mess up the index math 😬
public final class SingleSectionCollectionViewDiffCalculator<Value: Equatable> {

    public weak var collectionView: UICollectionView?

    /// All insertion/deletion calls will be made for items at this section.
    public let sectionIndex: Int

    public func numberOfItems(inSection section: Int) -> Int {
        guard section == self.sectionIndex else {
            fatalError("trying to get the number of items for a section that isn't yours!")
        }
        return items.count
    }

    /// Set this variable to automatically trigger the correct item insertion/deletions
    /// on your collection view.
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
