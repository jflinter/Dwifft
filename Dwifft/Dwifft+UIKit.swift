//
//  Dwifft+UIKit.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
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
    public var insertionAnimation = UITableView.RowAnimation.automatic, deletionAnimation = UITableView.RowAnimation.automatic

    override internal func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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

    override internal func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]) {
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
    public var insertionAnimation = UITableView.RowAnimation.automatic {
        didSet {
            self.internalDiffCalculator.insertionAnimation = self.insertionAnimation 
        }
    }
    
    public var deletionAnimation = UITableView.RowAnimation.automatic {
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
            self.internalDiffCalculator.sectionedValues = AbstractDiffCalculator<Int, Value>.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
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
        let initialSectionedValues = AbstractDiffCalculator<Int, Value>.buildSectionedValues(values: initialRows, sectionIndex: sectionIndex)
        self.internalDiffCalculator = TableViewDiffCalculator(tableView: tableView, initialSectionedValues: initialSectionedValues)
        self.sectionIndex = sectionIndex
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
            self.internalDiffCalculator.sectionedValues = AbstractDiffCalculator<Int, Value>.buildSectionedValues(values: newValue, sectionIndex: self.sectionIndex)
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
        self.internalDiffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialSectionedValues: AbstractDiffCalculator<Int, Value>.buildSectionedValues(values: initialItems, sectionIndex: sectionIndex))
        self.sectionIndex = sectionIndex
    }

    private let internalDiffCalculator: CollectionViewDiffCalculator<Int, Value>
    
}

#endif
