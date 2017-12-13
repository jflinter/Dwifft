//
//  AbstractDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 12/11/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

import Foundation

/// A parent class for all diff calculators. Don't use it directly.
public class AbstractDiffCalculator<Section: Equatable, Value: Equatable> {
    
    internal init(initialSectionedValues: SectionedValues<Section, Value>) {
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
        #if os(iOS) || os(tvOS)
            let row = indexPath.row
        #endif
        #if os(macOS)
            let row = indexPath.item
        #endif
        return self.sectionedValues[indexPath.section].1[row]
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
    
    internal static func buildSectionedValues(values: [Value], sectionIndex: Int) -> SectionedValues<Int, Value> {
        let firstRows = (0..<sectionIndex).map { ($0, [Value]()) }
        return SectionedValues(firstRows + [(sectionIndex, values)])
    }
    
    // UITableView and UICollectionView both perform assertions on the *current* number of rows/items before performing any updates. As such, the `sectionedValues` property must be backed by an internal value that does not change until *after* `beginUpdates`/`performBatchUpdates` has been called.
    internal final var _sectionedValues: SectionedValues<Section, Value>
    internal func processChanges(newState: SectionedValues<Section, Value>, diff: [SectionedDiffStep<Section, Value>]){
        fatalError("override me")
    }
}
