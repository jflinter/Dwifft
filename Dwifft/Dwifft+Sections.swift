//
//  Dwifft+Sections.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

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


    /// Returns a new SectionedValues appending a new key-value pair. I think this might be useful
    /// if you're building up a SectionedValues conditionally? (Well, I hope it is, anyway.)
    ///
    /// - Parameter sectionAndValue: the new key-value pair
    /// - Returns: a new SectionedValues containing the receiever's contents plus the new pair.
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

// TODO test please
public extension SectionedValues where Section: Comparable, Section: Hashable, Value: Comparable {

    /// This is a "convenience initializer" of sorts for SectionedValues. It acknowledges
    /// that sometimes you have an array of things that are naturally "groupable" - maybe
    /// a list of names in an address book, that can be grouped into their first initial,
    /// or a bunch of events that can be grouped into buckets of timestamps. The sections
    /// in the resultant `SectionedValues` will be returned in sorted order, according to
    /// their implementation of `Comparable`.
    ///
    /// - Parameters:
    ///   - values: All of the values that will end up in the `SectionedValues` you're making.
    ///   - valueToSection: A function that maps each value to the section it will inhabit.
    ///     In the above examples, this would take a name and return its first initial,
    ///     or take an event and return its bucketed timestamp.
    ///   - sortSections: If specified, this is a custom function you can use to sort your
    ///     sections instead of their `Comparable` implementation.
    ///   - sortValues: If specified, this is a custom function you can use to sort the values
    ///     in each section instead of their `Comparable` implementation.
    public init(
        values: [Value],
        valueToSection: ((Value) -> Section),
        sortSections: ((Section, Section) -> Bool)? = nil,
        sortValues: ((Value, Value) -> Bool)? = nil) {
        let dictionary: [Section: [Value]] = values.reduce([:]) { (accum, value) in
            var next = accum
            let section = valueToSection(value)
            var current = next[section] ?? []
            current.append(value)
            next[section] = current
            return next
        }
        let sortedSections: [Section]
        if let sortSections = sortSections {
            sortedSections = dictionary.keys.sorted(by: sortSections)
        } else {
            sortedSections = dictionary.keys.sorted()
        }
        self.init(sortedSections.map { section in
            let values = dictionary[section] ?? []
            let sortedValues: [Value]
            if let sortValues = sortValues {
                sortedValues = values.sorted(by: sortValues)
            } else {
                sortedValues = values.sorted()
            }
            return (section, sortedValues)
        })
    }
}

extension Dwifft {

    /// Returns the sequence of `SectionedDiffStep`s required to transform one `SectionedValues` into another.
    ///
    /// - Parameters:
    ///   - lhs: a `SectionedValues`
    ///   - rhs: another, uh, `SectionedValues`
    /// - Returns: the series of transformations that, when applied to `lhs`, will yield `rhs`.
    public static func diff<Section: Equatable, Value: Equatable>(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> [SectionedDiffStep<Section, Value>] {
        if lhs.sections == rhs.sections {
            let allResults: [[SectionedDiffStep<Section, Value>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = Dwifft.diff(lValues, rValues)
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
            let sectionDiff = Dwifft.diff(lhs.sections, rhs.sections)
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

    /// Applies a diff to a `SectionedValues`. The following should always be true:
    /// Given `x: SectionedValues<S,T>, y: SectionedValues<S,T>`,
    /// `Dwifft.apply(Dwifft.diff(lhs: x, rhs: y), toSectionedValues: x) == y`
    ///
    /// - Parameters:
    ///   - diff: a diff, as computed by calling `Dwifft.diff`. Note that you *must* be careful to
    ///   not modify said diff before applying it, and to only apply it to the left hand side of a
    ///   previous call to `Dwifft.diff`. If not, this can (and probably will) trigger an array out of bounds exception.
    ///   - lhs: a `SectionedValues`.
    /// - Returns: `lhs`, transformed by `diff`.
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

/// These get returned from calls to Dwifft.diff(). They represent insertions or deletions
/// that need to happen to transform one `SectionedValues` into another.
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
