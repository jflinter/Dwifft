//
//  Dwifft2D.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

// TODO document me please


/// SectionedValues represents, well, a bunch of sections and the values they represent.
/// You can think of it sort of like an "ordered dictionary", or an order of key-pairs.
/// If you are diffing a multidimensional structure of values (what might normally be,
/// for example, a 2D array), you will want to use this.
public struct SectionedValues<Section: Equatable, Value: Equatable>: Equatable {

    /// Initializes the struct with an array of key-pairs.
    ///
    /// - Parameter sectionsAndValues: An array of tuples. The first element in the tuple is
    /// the value of the section. The second element is an array of values to be associated with
    /// that section. Ordering matters, obviously. Note, it's totally ok if `sectionsAndValues`
    /// contains duplicate sections (or duplicate values within those sections).
    public init(_ sectionsAndValues: [(Section, [Value])] = []) {
        self.sectionsAndValues = sectionsAndValues
    }
    public let sectionsAndValues: [(Section, [Value])]
    public var count: Int { return self.sectionsAndValues.count }

    internal var sections: [Section] { get { return self.sectionsAndValues.map { $0.0 } } }
    internal subscript(i: Int) -> (Section, [Value]) {
        return self.sectionsAndValues[i]
    }

    public func appending(sectionAndValue: (Section, [Value])) -> SectionedValues<Section, Value> {
        return SectionedValues(self.sectionsAndValues + [sectionAndValue])
    }

    public func applying(_ diff: Diff2D<Section, Value>) -> SectionedValues<Section, Value> {
        var tmp = self
        for result in diff.results {
            tmp = tmp.applyingStep(step: result)
        }
        return tmp
    }

    internal mutating func applyingStep(step: DiffStep2D<Section, Value>) -> SectionedValues<Section, Value> {
        var sectionsAndValues = self.sectionsAndValues
        switch step {
        case let .sectionInsert(sectionIndex, val):
            sectionsAndValues.insert((val, []), at: sectionIndex)
        case let .sectionDelete(sectionIndex, _):
            sectionsAndValues.remove(at: sectionIndex)
        case let .insert(sectionIndex, rowIndex, val):
            sectionsAndValues[sectionIndex].1.insert(val, at: rowIndex)
        case let .delete(sectionIndex, rowIndex, _):
            sectionsAndValues[sectionIndex].1.remove(at: rowIndex)
        }
        return SectionedValues(sectionsAndValues)
    }

    public static func ==(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Bool {
        if lhs.sectionsAndValues.count != rhs.sectionsAndValues.count { return false }
        for i in 0..<(lhs.sectionsAndValues.count) {
            let ltuple = lhs.sectionsAndValues[i]
            let rtuple = rhs.sectionsAndValues[i]
            if (ltuple.0 != rtuple.0 || ltuple.1 != rtuple.1) {
                return false
            }
        }
        return true
    }
}

// TODO example app
extension SectionedValues where Section: Comparable, Section: Hashable, Value: Comparable {
    init(values: [Value], valueToSection: ((Value) -> Section)) {
        let dictionary: [Section: [Value]] = values.reduce([:]) { (accum, value) in
            var next = accum
            let section = valueToSection(value)
            var current = next[section] ?? []
            current.append(value)
            next[section] = current
            return next
        }
        self.init(dictionary.keys.sorted().map { section in
            (section, dictionary[section]?.sorted() ?? [])
        })
    }
}


public struct Diff2D<Section: Equatable, Value: Equatable>: CustomDebugStringConvertible {
    public static func diff(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Diff2D {
        let results = Diff2D.buildResults(lhs, rhs)
        return Diff2D(
            lhs: lhs,
            rhs: rhs,
            results: results
        )
    }

    private init(
        lhs: SectionedValues<Section, Value>,
        rhs: SectionedValues<Section, Value>,
        results: [DiffStep2D<Section, Value>]
    ) {
        self.lhs = lhs
        self.rhs = rhs
        self.results = results
    }

    private let lhs: SectionedValues<Section, Value>
    private let rhs: SectionedValues<Section, Value>
    let results: [DiffStep2D<Section, Value>]


    public func reversed() -> Diff2D<Section, Value> {
        return Diff2D.diff(lhs: self.rhs, rhs: self.lhs)
    }

    private static func buildResults(_ lhs: SectionedValues<Section, Value>, _ rhs: SectionedValues<Section, Value>) -> [DiffStep2D<Section, Value>] {
        if lhs.sections == rhs.sections {
            let allResults: [[DiffStep2D<Section, Value>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = lValues.diff(rValues)
                let results: [DiffStep2D<Section, Value>] = rowDiff.results.map { result in
                    switch result {
                    case let .insert(j, t): return DiffStep2D.insert(i, j, t)
                    case let .delete(j, t): return DiffStep2D.delete(i, j, t)
                    }
                }
                return results
            }
            let flattened = allResults.flatMap { $0 }
            let insertions = flattened.filter { result in
                if case .insert = result { return true }
                return false
            }
            let deletions = flattened.filter { result in
                if case .delete = result { return true }
                return false
            }
            return deletions + insertions

        } else {
            var middleSectionsAndValues = lhs.sectionsAndValues
            let sectionDiff = lhs.sections.diff(rhs.sections)
            var sectionInsertions: [DiffStep2D<Section, Value>] = []
            var sectionDeletions: [DiffStep2D<Section, Value>] = []
            for result in sectionDiff.results {
                switch result {
                case let .insert(i, s):
                    sectionInsertions.append(DiffStep2D.sectionInsert(i, s))
                    middleSectionsAndValues.insert((s, []), at: i)
                case let .delete(i, s):
                    sectionDeletions.append(DiffStep2D.sectionDelete(i, s))
                    middleSectionsAndValues.remove(at: i)
                }
            }

            let middle = SectionedValues(middleSectionsAndValues)
            let rowResults = Diff2D.buildResults(middle, rhs)

            // we need to calculate a mapping from the final section indices to the original
            // section indices. This lets us perform the deletions before the section deletions,
            // which makes UITableView + UICollectionView happy. See https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html#//apple_ref/doc/uid/TP40007451-CH10-SW9
            var indexMapping = Array(0..<lhs.count)
            for deletion in sectionDeletions {
                indexMapping.remove(at: deletion.section)
            }
            for insertion in sectionInsertions {
                indexMapping.insert(-1, at: insertion.section)
            }
            var mapping = [Int: Int]()
            for (i, j) in indexMapping.enumerated() {
                mapping[i] = j
            }

            let deletions = rowResults.filter { result in
                if case .delete = result {
                    return true
                }
                return false
            }

            let insertions = rowResults.filter { result in
                if case .insert = result {
                    return true
                }
                return false
            }

            let mappedDeletions: [DiffStep2D<Section, Value>] = deletions.map { deletion in
                guard case let .delete(section, row, val) = deletion else { fatalError("not possible") }
                guard let newIndex = mapping[section], newIndex != -1 else { fatalError("not possible") }
                return .delete(newIndex, row, val)
            }

            return mappedDeletions + sectionDeletions + sectionInsertions + insertions

        }
    }

    public var debugDescription: String {
        return "[" + self.results.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

public enum DiffStep2D<Section, Value>: CustomDebugStringConvertible {
    case insert(Int, Int, Value)
    case delete(Int, Int, Value)
    case sectionInsert(Int, Section)
    case sectionDelete(Int, Section)

    public var section: Int {
        switch self {
        case let .insert(s, _, _): return s
        case let .delete(s, _, _): return s
        case let .sectionInsert(s, _): return s
        case let .sectionDelete(s, _): return s
        }
    }

    public var row: Int? {
        switch self {
        case let .insert(_, r, _): return r
        case let .delete(_, r, _): return r
        case .sectionInsert, .sectionDelete: return nil
        }
    }

    public var debugDescription: String {
        switch self {
        case let .sectionDelete(s, _): return "ds(\(s))"
        case let .sectionInsert(s, _): return "is(\(s))"
        case let .delete(section, row, _): return "d(\(section) \(row))"
        case let .insert(section, row, _): return "i(\(section) \(row))"
        }
    }
}
