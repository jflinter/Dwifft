//
//  Dwifft2D.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

public struct SectionedValues<Section: Equatable, Value: Equatable>: Equatable {
    public init(_ sectionsAndValues: [(Section, [Value])] = []) {
        self.sectionsAndValues = sectionsAndValues
    }
    public var sectionsAndValues: [(Section, [Value])]

    public var sections: [Section] { get { return self.sectionsAndValues.map { $0.0 } } }
    public var count: Int { return self.sectionsAndValues.count }
    public subscript(i: Int) -> (Section, [Value]) {
        return self.sectionsAndValues[i]
    }

    public func apply(_ diff: Diff2D<Section, Value>) -> SectionedValues<Section, Value> {
        var tmp = self
        for result in diff.results {
            tmp.applyStep(step: result)
        }
        return tmp
    }

    public mutating func applyStep(step: DiffStep2D<Section, Value>) {
        switch step {
        case .sectionInsert(let sectionIndex, let val):
            self.sectionsAndValues.insert((val, []), at: sectionIndex)
        case .sectionDelete(let sectionIndex, _):
            self.sectionsAndValues.remove(at: sectionIndex)
        case .insert(let sectionIndex, let rowIndex, let val):
            self.sectionsAndValues[sectionIndex].1.insert(val, at: rowIndex)
        case .delete(let sectionIndex, let rowIndex, _):
            self.sectionsAndValues[sectionIndex].1.remove(at: rowIndex)
        }
    }
}

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

public func ==<Section, Value>(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Bool {
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

fileprivate struct DiffResults<Section, Value> {
    let deletions: [DiffStep2D<Section, Value>]
    let sectionDeletions: [DiffStep2D<Section, Value>]
    let sectionInsertions: [DiffStep2D<Section, Value>]
    let insertions: [DiffStep2D<Section, Value>]
}

public struct Diff2D<Section: Equatable, Value: Equatable>: CustomDebugStringConvertible {
    public static func diff(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Diff2D {
        let results = Diff2D.buildResults(lhs, rhs)
        return Diff2D(
            lhs: lhs,
            rhs: rhs,
            sectionDeletions: results.sectionDeletions,
            sectionInsertions: results.sectionInsertions,
            deletions: results.deletions,
            insertions: results.insertions
        )
    }

    private init(
        lhs: SectionedValues<Section, Value>,
        rhs: SectionedValues<Section, Value>,
        sectionDeletions: [DiffStep2D<Section, Value>],
        sectionInsertions: [DiffStep2D<Section, Value>],
        deletions: [DiffStep2D<Section, Value>],
        insertions: [DiffStep2D<Section, Value>]
    ) {
        self.lhs = lhs
        self.rhs = rhs
        self.sectionDeletions = sectionDeletions
        self.sectionInsertions = sectionInsertions
        self.deletions = deletions
        self.insertions = insertions
        self.results = deletions + sectionDeletions + sectionInsertions + insertions
    }

    private let lhs: SectionedValues<Section, Value>
    private let rhs: SectionedValues<Section, Value>
    let results: [DiffStep2D<Section, Value>]
    let deletions: [DiffStep2D<Section, Value>]
    let sectionDeletions: [DiffStep2D<Section, Value>]
    let sectionInsertions: [DiffStep2D<Section, Value>]
    let insertions: [DiffStep2D<Section, Value>]


    public func reversed() -> Diff2D<Section, Value> {
        return Diff2D.diff(lhs: self.rhs, rhs: self.lhs)
    }

    private static func buildResults(_ lhs: SectionedValues<Section, Value>, _ rhs: SectionedValues<Section, Value>) -> DiffResults<Section, Value> {
        if lhs.sections == rhs.sections {
            let allResults: [[DiffStep2D<Section, Value>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = lValues.diff(rValues)
                let results: [DiffStep2D<Section, Value>] = rowDiff.results.map { result in
                    switch result {
                    case .insert(let j, let t): return DiffStep2D.insert(i, j, t)
                    case .delete(let j, let t): return DiffStep2D.delete(i, j, t)
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
            return DiffResults<Section, Value>(
                deletions: deletions,
                sectionDeletions: [],
                sectionInsertions: [],
                insertions: insertions
            )

        } else {
            var middleSectionsAndValues = lhs.sectionsAndValues
            let sectionDiff = lhs.sections.diff(rhs.sections)
            var sectionInsertions: [DiffStep2D<Section, Value>] = []
            var sectionDeletions: [DiffStep2D<Section, Value>] = []
            for result in sectionDiff.results {
                switch result {
                case .insert(let i, let s):
                    sectionInsertions.append(DiffStep2D.sectionInsert(i, s))
                    middleSectionsAndValues.insert((s, []), at: i)
                case .delete(let i, let s):
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

            let mappedDeletions: [DiffStep2D<Section, Value>] = rowResults.deletions.map { deletion in
                guard case .delete(let section, let row, let val) = deletion else { fatalError("not possible") }
                guard let newIndex = mapping[section], newIndex != -1 else { fatalError("not possible") }
                return .delete(newIndex, row, val)
            }

            return DiffResults<Section, Value>(
                deletions: mappedDeletions,
                sectionDeletions: sectionDeletions,
                sectionInsertions: sectionInsertions,
                insertions: rowResults.insertions
            )
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

    var section: Int {
        switch self {
        case .insert(let s, _, _): return s
        case .delete(let s, _, _): return s
        case .sectionInsert(let s, _): return s
        case .sectionDelete(let s, _): return s
        }
    }

    var row: Int? {
        switch self {
        case .insert(_, let r, _): return r
        case .delete(_, let r, _): return r
        case .sectionInsert, .sectionDelete: return nil
        }
    }

    public var debugDescription: String {
        switch self {
        case .sectionDelete(let s, _): return "ds(\(s))"
        case .sectionInsert(let s, _): return "is(\(s))"
        case .delete(let section, let row, _): return "d(\(section) \(row))"
        case .insert(let section, let row, _): return "i(\(section) \(row))"
        }
    }
}
