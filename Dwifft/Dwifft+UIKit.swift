//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

//#if os(iOS) TODO

import UIKit

public enum DwifftSection {
    case section(identifier: AnyHashable, values: [AnyHashable])
    case placeholder(identifier: AnyHashable, numberOfRows: Int)
    public var identifier: AnyHashable {
        switch self {
        case .section(let identifier, _): return identifier
        case .placeholder(let identifier, _): return identifier
        }
    }
}

private extension DwifftSection {
    var asTuple: (AnyHashable, [AnyHashable]) {
        switch self {
        case .section(let identifier, let values): return (identifier, values)
        case .placeholder(let identifier, _): return (identifier, [])
        }
    }
}

public protocol DiffCalculator: class {
    var sections: [DwifftSection] { get set }
    func numberOfSections() -> Int
    func value(forSection: Int) -> DwifftSection
    func numberOfObjects(inSection section: Int) -> Int
    func value(atIndexPath indexPath: IndexPath) -> AnyHashable?

    func processChanges(
        newState: [DwifftSection],
        deletionIndexPaths: [IndexPath],
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        insertionIndexPaths: [IndexPath]
    )
    func internalSections() -> [DwifftSection]
}

public extension DiffCalculator {
    public func numberOfSections() -> Int {
        return self.sections.count
    }

    public func value(forSection: Int) -> DwifftSection {
        return self.sections[forSection]
    }

    public func numberOfObjects(inSection section: Int) -> Int {
        let section = self.sections[section]
        switch section {
        case .placeholder(_, let numberOfRows): return numberOfRows
        case .section(_, let values): return values.count
        }
    }

    public func value(atIndexPath indexPath: IndexPath) -> AnyHashable? {
        let section = self.sections[indexPath.section]
        switch section {
        case .placeholder: return nil
        case .section(_, let values): return values[indexPath.row]
        }
    }

    public var sections: [DwifftSection] {
        get {
            return internalSections()
        }
        set {
            let oldSections = SectionedValues(sections.map { $0.asTuple })
            let newSections = SectionedValues(newValue.map { $0.asTuple })
            let diff = Diff2D.diff(lhs: oldSections, rhs: newSections)
            if (diff.results.count > 0) {

                let deletionIndexPaths: [IndexPath] = diff.deletions.flatMap { d in
                    guard let row = d.row else { return nil }
                    return IndexPath(row: row, section: d.section)
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
                let insertionIndexPaths: [IndexPath] = diff.insertions.flatMap { d in
                    guard let row = d.row else { return nil }
                    return IndexPath(row: row, section: d.section)
                }

                // TODO does rendering offscreen changes without animation improve performance meaningfully?

                self.processChanges(
                    newState: newValue,
                    deletionIndexPaths: deletionIndexPaths,
                    sectionDeletionIndices: sectionDeletionIndices,
                    sectionInsertionIndices: sectionInsertionIndices,
                    insertionIndexPaths: insertionIndexPaths
                )
                
            }

        }
    }

}

public class TableViewDiffCalculator: DiffCalculator {

    public weak var tableView: UITableView?

    private var _sections: [DwifftSection]

    public init(tableView: UITableView, initialSections: [DwifftSection] = []) {
        self.tableView = tableView
        self._sections = initialSections
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    public func internalSections() -> [DwifftSection] {
        return self._sections
    }

    public func processChanges(
        newState: [DwifftSection],
        deletionIndexPaths: [IndexPath],
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        insertionIndexPaths: [IndexPath]
    ){
        guard let tableView = self.tableView else { return }
        tableView.beginUpdates()
        self._sections = newState
        tableView.deleteSections(sectionDeletionIndices, with: self.deletionAnimation)
        tableView.insertSections(sectionInsertionIndices, with: self.insertionAnimation)
        tableView.deleteRows(at: deletionIndexPaths, with: self.deletionAnimation)
        tableView.insertRows(at: insertionIndexPaths, with: self.insertionAnimation)
        tableView.endUpdates()
    }
}

public class CollectionViewDiffCalculator<S: Equatable, T: Equatable> : DiffCalculator {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView, initialSections: [DwifftSection] = []) {
        self.collectionView = collectionView
        _sections = initialSections
    }

    // Since UICollectionView (unlike UITableView) takes a block which must update its data source and trigger animations, we need to trigger the changes on set, instead of explicitly before and after set. This backing array lets us use a getter/setter in the exposed property.
    private var _sections: [DwifftSection]
    public func internalSections() -> [DwifftSection] {
        return _sections
    }

    public func processChanges(
        newState: [DwifftSection],
        deletionIndexPaths: [IndexPath],
        sectionDeletionIndices: IndexSet,
        sectionInsertionIndices: IndexSet,
        insertionIndexPaths: [IndexPath]
    ) {
        guard let collectionView = self.collectionView else { return }
        collectionView.performBatchUpdates({ () -> Void in
            self._sections = newState
            collectionView.deleteSections(sectionDeletionIndices)
            collectionView.insertSections(sectionInsertionIndices)
            collectionView.deleteItems(at: deletionIndexPaths)
            collectionView.insertItems(at: insertionIndexPaths)
        }, completion: nil)
    }

}

//#endif
