//
//  Dwifft+Sections.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

// TODO document me please


/// SectionedValues represents, well, a bunch of sections and their associated values.
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

extension Dwifft {
    public static func diff<Section: Equatable, Value: Equatable>(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> [SectionedDiffStep<Section, Value>] {
        if lhs.sections == rhs.sections {
            let allResults: [[SectionedDiffStep<Section, Value>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = Dwifft.diff(lhs: lValues, rhs: rValues)
                let results: [SectionedDiffStep<Section, Value>] = rowDiff.map { result in
                    switch result {
                    case let .insert(j, t): return SectionedDiffStep.insert(i, j, t)
                    case let .delete(j, t): return SectionedDiffStep.delete(i, j, t)
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
            let sectionDiff = Dwifft.diff(lhs: lhs.sections, rhs: rhs.sections)
            var sectionInsertions: [SectionedDiffStep<Section, Value>] = []
            var sectionDeletions: [SectionedDiffStep<Section, Value>] = []
            for result in sectionDiff {
                switch result {
                case let .insert(i, s):
                    sectionInsertions.append(SectionedDiffStep.sectionInsert(i, s))
                    middleSectionsAndValues.insert((s, []), at: i)
                case let .delete(i, s):
                    sectionDeletions.append(SectionedDiffStep.sectionDelete(i, s))
                    middleSectionsAndValues.remove(at: i)
                }
            }

            let middle = SectionedValues(middleSectionsAndValues)
            let rowResults = Dwifft.diff(lhs: middle, rhs: rhs)

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

            let mappedDeletions: [SectionedDiffStep<Section, Value>] = deletions.map { deletion in
                guard case let .delete(section, row, val) = deletion else { fatalError("not possible") }
                guard let newIndex = mapping[section], newIndex != -1 else { fatalError("not possible") }
                return .delete(newIndex, row, val)
            }

            return mappedDeletions + sectionDeletions + sectionInsertions + insertions
            
        }
    }

    public static func apply<Section, Value>(diff: [SectionedDiffStep<Section, Value>], toSectionedValues lhs: SectionedValues<Section, Value>) -> SectionedValues<Section, Value> {
        var sectionsAndValues = lhs.sectionsAndValues
        for result in diff {
            switch result {
            case let .sectionInsert(sectionIndex, val):
                sectionsAndValues.insert((val, []), at: sectionIndex)
            case let .sectionDelete(sectionIndex, _):
                sectionsAndValues.remove(at: sectionIndex)
            case let .insert(sectionIndex, rowIndex, val):
                sectionsAndValues[sectionIndex].1.insert(val, at: rowIndex)
            case let .delete(sectionIndex, rowIndex, _):
                sectionsAndValues[sectionIndex].1.remove(at: rowIndex)
            }
        }
        return SectionedValues(sectionsAndValues)
    }
}

public enum SectionedDiffStep<Section, Value>: CustomDebugStringConvertible {
    case insert(Int, Int, Value)
    case delete(Int, Int, Value)
    case sectionInsert(Int, Section)
    case sectionDelete(Int, Section)

    fileprivate var section: Int {
        switch self {
        case let .insert(s, _, _): return s
        case let .delete(s, _, _): return s
        case let .sectionInsert(s, _): return s
        case let .sectionDelete(s, _): return s
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
