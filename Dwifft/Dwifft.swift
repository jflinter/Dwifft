//
//  Dwifft.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

public struct Diff<T>: CustomDebugStringConvertible {
    public let results: [DiffStep<T>]
    public let insertions: [DiffStep<T>]
    public let deletions: [DiffStep<T>]

    init(results: [DiffStep<T>]) {
        let insertions = results.filter({ $0.isInsertion }).sorted(by: { $0.idx < $1.idx })
        let deletions = results.filter({ !$0.isInsertion }).sorted(by: { $0.idx > $1.idx })
        self.init(sortedInsertions: insertions, sortedDeletions: deletions)
    }

    fileprivate init(sortedInsertions: [DiffStep<T>], sortedDeletions: [DiffStep<T>]) {
        self.insertions = sortedInsertions
        self.deletions = sortedDeletions
        self.results = sortedDeletions + sortedInsertions
    }

    public func reversed() -> Diff<T> {
        let reversedResults = self.results.reversed().map { (result: DiffStep<T>) -> DiffStep<T> in
            switch result {
            case .insert(let i, let j):
                return .delete(i, j)
            case .delete(let i, let j):
                return .insert(i, j)
            }
        }
        return Diff<T>(results: reversedResults)
    }
    public var debugDescription: String {
        return "[" + self.results.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

/// These get returned from calls to Array.diff(). They represent insertions or deletions that need to happen to transform array a into array b.
public enum DiffStep<T> : CustomDebugStringConvertible {
    case insert(Int, T)
    case delete(Int, T)
    var isInsertion: Bool {
        switch(self) {
        case .insert:
            return true
        case .delete:
            return false
        }
    }
    public var debugDescription: String {
        switch(self) {
        case .insert(let i, let j):
            return "+\(j)@\(i)"
        case .delete(let i, let j):
            return "-\(j)@\(i)"
        }
    }
    public var idx: Int {
        switch(self) {
        case .insert(let i, _):
            return i
        case .delete(let i, _):
            return i
        }
    }
    public var value: T {
        switch(self) {
        case .insert(let j):
            return j.1
        case .delete(let j):
            return j.1
        }
    }
}

private enum Result<T>{
    case done(T)
    case call(() -> Result<T>)
}

public extension Array where Element: Equatable {

    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(_ other: [Element]) -> Diff<Element> {

        func diffInternal(
            _ table: [[Int]],
            _ x: [Element],
            _ y: [Element],
            _ i: Int,
            _ j: Int,
            _ currentResults: ([DiffStep<Element>], [DiffStep<Element>])
            ) -> Result<([DiffStep<Element>], [DiffStep<Element>])> {
            if i == 0 && j == 0 {
                return .done(currentResults)
            }
            else {
                // TODO this might be faster with a linked list.
                return .call {
                    var nextResults = currentResults
                    if i == 0 {
                        nextResults.0 = [DiffStep.insert(j-1, y[j-1])] + nextResults.0
                        return diffInternal(table, x, y, i, j-1, nextResults)
                    } else if j == 0 {
                        nextResults.1 = nextResults.1 + [DiffStep.delete(i-1, x[i-1])]
                        return diffInternal(table, x, y, i - 1, j, nextResults)
                    } else if table[i][j] == table[i][j-1] {
                        nextResults.0 = [DiffStep.insert(j-1, y[j-1])] + nextResults.0
                        return diffInternal(table, x, y, i, j-1, nextResults)
                    } else if table[i][j] == table[i-1][j] {
                        nextResults.1 = nextResults.1 + [DiffStep.delete(i-1, x[i-1])]
                        return diffInternal(table, x, y, i - 1, j, nextResults)
                    } else {
                        return diffInternal(table, x, y, i-1, j-1, nextResults)
                    }
                }
            }
        }

        if self.isEmpty {
            return Diff(sortedInsertions: other.enumerated().map(DiffStep.insert), sortedDeletions: [])
        } else if other.isEmpty {
            return Diff(sortedInsertions: [], sortedDeletions: self.enumerated().map(DiffStep.delete).reversed())
        }

        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        var result = diffInternal(table, self, other, self.count, other.count, ([], []))
        while case .call(let f) = result {
            result = f()
        }
        if case let .done(accum) = result {
            return Diff(sortedInsertions: accum.0, sortedDeletions: accum.1)
        } else {
            fatalError("unreachable code")
        }
    }

    /// Applies a generated diff to an array. The following should always be true:
    /// Given x: [T], y: [T], x.apply(x.diff(y)) == y
    public func apply(_ diff: Diff<Element>) -> Array<Element> {
        var copy = self
        for result in diff.results { copy.applyStep(result) }
        return copy
    }

    public mutating func applyStep(_ step: DiffStep<Element>) {
        switch step {
        case .delete(let idx, _):
            self.remove(at: idx)
        case .insert(let idx, let val):
            self.insert(val, at: idx)
        }
    }

}

public extension Array where Element: Equatable {

    /// Returns the longest common subsequence between two arrays.
    public func LCS(_ other: [Element]) -> [Element] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.lcsFromIndices(table, self, other, self.count, other.count)
    }

    /// Walks back through the generated table to generate the LCS.
    fileprivate static func lcsFromIndices(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
        if i == 0 || j == 0 {
            return []
        } else if x[i-1] == y[j-1] {
            return lcsFromIndices(table, x, y, i - 1, j - 1) + [x[i - 1]]
        } else if table[i-1][j] > table[i][j-1] {
            return lcsFromIndices(table, x, y, i - 1, j)
        } else {
            return lcsFromIndices(table, x, y, i, j - 1)
        }
    }

}

internal struct MemoizedSequenceComparison<T: Equatable> {
    static func buildTable(_ x: [T], _ y: [T], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n {
            for j in 0...m {
                if (i == 0 || j == 0) {
                    table[i][j] = 0
                }
                else if x[i-1] == y[j-1] {
                    table[i][j] = table[i-1][j-1] + 1
                } else {
                    table[i][j] = max(table[i-1][j], table[i][j-1])
                }
            }
        }
        return table
    }
}

// MARK - 2D
// TODO split into separate file

public struct SectionedValues<S: Equatable, T: Equatable>: Equatable {
    public init(_ sectionsAndValues: [(S, [T])] = []) {
        self.sectionsAndValues = sectionsAndValues
        self._sections = sectionsAndValues.map { $0.0 }
    }
    public var sectionsAndValues: [(S, [T])] { didSet {
        self._sections = sectionsAndValues.map { $0.0 }
    }}
    private var _sections: [S]
    public var sections: [S] { get { return _sections } }
    public var count: Int { return self.sectionsAndValues.count }
    public subscript(i: Int) -> (S, [T]) {
        return self.sectionsAndValues[i]
    }

    public func apply(_ diff: Diff2D<S, T>) -> SectionedValues<S, T> {
        var tmp = self
        for result in diff.results {
            switch result {
            case .sectionInsert(let sectionIndex, let val):
                tmp.sectionsAndValues.insert((val, []), at: sectionIndex)
            case .sectionDelete(let sectionIndex, _):
                tmp.sectionsAndValues.remove(at: sectionIndex)
            case .insert(let sectionIndex, let rowIndex, let val):
                tmp.sectionsAndValues[sectionIndex].1.insert(val, at: rowIndex)
            case .delete(let sectionIndex, let rowIndex, _):
                tmp.sectionsAndValues[sectionIndex].1.remove(at: rowIndex)
            }
        }
        return tmp
    }
}

public func ==<S, T>(lhs: SectionedValues<S, T>, rhs: SectionedValues<S, T>) -> Bool {
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


fileprivate enum SectionOrValue<S: Equatable, T: Equatable>: CustomDebugStringConvertible, Equatable {
    case section(S)
    case value(S, T)
    init(_ section: S, value: T) {
        self = .value(section, value)
    }
    init(_ section: S) {
        self = .section(section)
    }

    public var isSection: Bool {
        switch self {
            case .section: return true
            default: return false
        }
    }

    public var debugDescription: String {
        switch self {
        case .section:
            return ","
        case .value(_, let t):
            if let x = t as? Int {
                return "\(x)"
            }
            return "?"
        }
    }
}

fileprivate func ==<S, T>(lhs: SectionOrValue<S, T>, rhs: SectionOrValue<S, T>) -> Bool {
    switch lhs {
    case .section(let l):
        if case .section(let r) = rhs, l == r {
            return true
        }
    case .value(let ls, let lv):
        if case .value(let rs, let rv) = rhs, ls == rs, lv == rv {
            return true
        }
    }
    return false
}

public struct Diff2D<S: Equatable, T: Equatable>: CustomDebugStringConvertible {
    init(lhs: SectionedValues<S, T>, rhs: SectionedValues<S, T>) {
        self.lhs = lhs
        self.rhs = rhs
        let results = Diff2D.buildResults(lhs, rhs)
        self.results = results.deletions + results.sectionDeletions + results.sectionInsertions + results.insertions
    }

    let lhs: SectionedValues<S, T>
    let rhs: SectionedValues<S, T>
    let results: [DiffStep2D<S, T>]

    private struct DiffResults<S, T> {
        let insertions: [DiffStep2D<S, T>]
        let deletions: [DiffStep2D<S, T>]
        let sectionInsertions: [DiffStep2D<S, T>]
        let sectionDeletions: [DiffStep2D<S, T>]
    }

    private static func buildResults(_ lhs: SectionedValues<S, T>, _ rhs: SectionedValues<S, T>) -> DiffResults<S, T> {
        if lhs.sections == rhs.sections {
            // todo: parallelize?
            let allResults: [[DiffStep2D<S, T>]] = (0..<lhs.sections.count).map { i in
                let lValues = lhs.sectionsAndValues[i].1
                let rValues = rhs.sectionsAndValues[i].1
                let rowDiff = lValues.diff(rValues)
                let results: [DiffStep2D<S, T>] = rowDiff.results.map { result in
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
            return DiffResults<S, T>(insertions: insertions, deletions: deletions, sectionInsertions: [], sectionDeletions: [])

        } else {
            var middleSectionsAndValues = lhs.sectionsAndValues
            let sectionDiff = lhs.sections.diff(rhs.sections)
            var sectionInsertions: [DiffStep2D<S, T>] = []
            var sectionDeletions: [DiffStep2D<S, T>] = []
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
            let deletedSections = Set<Int>(sectionDeletions.flatMap { deletion in
                guard case .sectionDelete(let i, _) = deletion else { fatalError("not possible") }
                return i
            })
            let rowDeletions: [[DiffStep2D<S, T>]] = lhs.sectionsAndValues.enumerated().flatMap { s, tuple in
                guard deletedSections.contains(s) else { return nil }
                return tuple.1.enumerated().map { r, value in
                    return DiffStep2D.delete(s, r, value)
                }
            }
            let flattenedRowDeletions: [DiffStep2D<S, T>] = rowDeletions.flatMap { $0 }.sorted { l, r in
                guard case .delete(let ls, let lr, _) = l, case .delete(let rs, let rr, _) = r else { fatalError("not possible") }
                return ls > rs || (ls == rs) && lr > rr
            }

            let middle = SectionedValues(middleSectionsAndValues)
            let rowResults = Diff2D.buildResults(middle, rhs)

            return DiffResults<S, T>(
                insertions: rowResults.insertions,
                deletions: flattenedRowDeletions + rowResults.deletions,
                sectionInsertions: sectionInsertions,
                sectionDeletions: sectionDeletions
            )
        }
    }

    public var debugDescription: String {
        return "[" + self.results.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

enum DiffStep2D<S, T>: CustomDebugStringConvertible {
    case insert(Int, Int, T)
    case delete(Int, Int, T)
    case sectionInsert(Int, S)
    case sectionDelete(Int, S)

    public var debugDescription: String {
        switch self {
        case .sectionDelete(let s, _): return "ds(\(s))"
        case .sectionInsert(let s, _): return "is(\(s))"
        case .delete(let section, let row, _): return "d(\(section) \(row))"
        case .insert(let section, let row, _): return "i(\(section) \(row))"
        }
    }
}
