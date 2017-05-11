//
//  Dwifft+UIKit.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit


/// A parent class for all diff calculators. Don't use it directly.
public class AbstractDiffCalculator<Section: Equatable, Value: Equatable> {

    fileprivate init(initialSectionedValues: SectionedValues<Section, Value>) {
        self._sectionedValues = initialSectionedValues
    }

    /// The number of sections in the diff calculator. Return this inside
    /// `numberOfSections(in: tableView)` or `numberOfSections(in: collectionView)`.
    /// Don't implement that method any other way (see the docs for `numberOfObjects(inSection:)`
    /// for more context).
    public final func numberOfSections() -> Int {
        return self.sectionedValues.sections.count
    }

    /// The section at a given index. If you implement `tableView:titleForHeaderInSection` or
    /// `collectionView:viewForSupplementaryElementOfKind:atIndexPath`, you can use this
    /// method to get information about that section out of Dwifft.
    ///
    /// - Parameter forSection: the index of the section you care about.
    /// - Returns: the Section at that index.
    public final func value(forSection: Int) -> Section {
        return self.sectionedValues[forSection].0
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
        return self.sectionedValues[section].1.count
    }


    /// The value at a given index path. Use this to implement
    /// `UITableViewDataSource.cellForRowAtIndexPath` or `UICollectionViewDataSource.cellForItemAtIndexPath`.
    ///
    /// - Parameter indexPath: the index path you are interested in
    /// - Returns: the thing at that index path
    public final func value(atIndexPath indexPath: IndexPath) -> Value {
        return self.sectionedValues[indexPath.section].1[indexPath.row]
    }


    /// Set this variable to automatically trigger the correct section/row/item insertion/deletions
    /// on your table/collection view.
    public final var sectionedValues: SectionedValues<Section, Value> {
        get {
            return _sectionedValues
        }
        set {
            let oldSectionedValues = sectionedValues
            let newSectionedValues = newValue
            let diff = Dwifft.diff(lhs: oldSectionedValues, rhs: newSectionedValues)
            if (diff.count > 0) {
                self.processChanges(newState: newSectionedValues, diff: diff)
            }
        }
    }

    // UITableView and UICollectionView both perform assertions on the *current* number of rows/items before performing any updates. As such, the `sectionedValues` property must be backed by an internal value that does not change until *after* `beginUpdates`/`performBatchUpdates` has been called.
    fileprivate final var _sectionedValues: SectionedValues<Section, Value>
    fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]){
        fatalError("override me")
    }
}


/// This class manages a `UITableView`'s rows and sections. It will make the necessary calls to
/// the table view to ensure that its UI is kept in sync with the contents of the `sectionedValues` property.
public final class TableViewDiffCalculator<Section: Equatable, Value: Equatable>: AbstractDiffCalculator<Section, Value> {

    /// The table view to be managed
    public weak var tableView: UITableView?

    /// Initializes a new diff calculator.
    ///
    /// - Parameters:
    ///   - tableView: the table view to be managed
    ///   - initialSectionedValues: optional - if specified, these will be the initial contents of the diff calculator.
    public init(tableView: UITableView?, initialSectionedValues: SectionedValues<Section, Value> = SectionedValues()) {
        self.tableView = tableView
        super.init(initialSectionedValues: initialSectionedValues)
    }

    /// You can change insertion/deletion animations like this! Fade works well.
    /// So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    override fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
        guard let tableView = self.tableView else { return }
        tableView.beginUpdates()
        self._sectionedValues = newState
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
/// of the `sectionedValues` property.
public final class CollectionViewDiffCalculator<Section: Equatable, Value: Equatable> : AbstractDiffCalculator<Section, Value> {

    /// The collection view to be managed.
    public weak var collectionView: UICollectionView?

    /// Initializes a new diff calculator.
    ///
    /// - Parameters:
    ///   - collectionView: the collection view to be managed.
    ///   - initialSectionedValues: optional - if specified, these will be the initial contents of the diff calculator.
    public init(collectionView: UICollectionView?, initialSectionedValues: SectionedValues<Section, Value> = SectionedValues()) {
        self.collectionView = collectionView
        super.init(initialSectionedValues: initialSectionedValues)
    }

    override fileprivate func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
        guard let collectionView = self.collectionView else { return }
        collectionView.performBatchUpdates({
            self._sectionedValues = newState
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
/// You'll be less likely to mess up the index math :P
public final class SingleSectionTableViewDiffCalculator<Value: Equatable> {

    /// The table view to be managed
    public weak var tableView: UITableView?

    /// All insertion/deletion calls will be made on this index.
    public let sectionIndex: Int

    /// You can change insertion/deletion animations like this! Fade works well.
    /// So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic {
        didSet {
            self.internalDiffCalculator.insertionAnimation = self.insertionAnimation 
        }
    }
    
    public var deletionAnimation = UITableViewRowAnimation.automatic {
        didSet {
            self.internalDiffCalculator.deletionAnimation = self.deletionAnimation 
        }
    }

    /// Set this variable to automatically trigger the correct row insertion/deletions
    /// on your table view.
    public var rows : [Value] {
        get {
            return self.internalDiffCalculator.sectionedValues[self.sectionIndex].1
        }
        set {
            self.internalDiffCalculator.sectionedValues = SingleSectionTableViewDiffCalculator.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
        }
    }

    /// Initializes a new diff calculator.
    ///
    /// - Parameters:
    ///   - tableView: the table view to be managed
    ///   - initialRows: optional - if specified, these will be the initial contents of the diff calculator.
    ///   - sectionIndex: optional - all insertion/deletion calls will be made on this index.
    public init(tableView: UITableView?, initialRows: [Value] = [], sectionIndex: Int = 0) {
        self.tableView = tableView
        self.internalDiffCalculator = TableViewDiffCalculator(tableView: tableView, initialSectionedValues: SingleSectionTableViewDiffCalculator.buildSectionedValues(values: initialRows, sectionIndex: sectionIndex))
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
/// You'll be less likely to mess up the index math :P
public final class SingleSectionCollectionViewDiffCalculator<Value: Equatable> {

    /// The collection view to be managed
    public weak var collectionView: UICollectionView?

    /// All insertion/deletion calls will be made for items at this section.
    public let sectionIndex: Int

    /// Set this variable to automatically trigger the correct item insertion/deletions
    /// on your collection view.
    public var items : [Value] {
        get {
            return self.internalDiffCalculator.sectionedValues[self.sectionIndex].1
        }
        set {
            self.internalDiffCalculator.sectionedValues = SingleSectionTableViewDiffCalculator.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
        }
    }

    /// Initializes a new diff calculator.
    ///
    /// - Parameters:
    ///   - tableView: the table view to be managed
    ///   - initialItems: optional - if specified, these will be the initial contents of the diff calculator.
    ///   - sectionIndex: optional - all insertion/deletion calls will be made on this index.
    public init(collectionView: UICollectionView?, initialItems: [Value] = [], sectionIndex: Int = 0) {
        self.collectionView = collectionView
        self.internalDiffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialSectionedValues: SingleSectionTableViewDiffCalculator.buildSectionedValues(values: initialItems, sectionIndex: sectionIndex))
        self.sectionIndex = sectionIndex
    }

    private let internalDiffCalculator: CollectionViewDiffCalculator<Int, Value>
    
}

#endif
