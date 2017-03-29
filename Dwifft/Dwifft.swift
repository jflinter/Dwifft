//
//  Dwifft.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

public struct Diff<T>: CustomDebugStringConvertible {
    public let results: [DiffStep<T>]
    init(results: [DiffStep<T>]) {
//        self.results = results.sorted { lhs, rhs in
//            if lhs.isInsertion && rhs.isInsertion {
//                return lhs.idx < rhs.idx
//            } else if lhs.isInsertion {
//                return false
//            } else if rhs.isInsertion {
//                return true
//            } else {
//                return lhs.idx > rhs.idx
//            }
//        }
        let insertions = results.filter({ $0.isInsertion }).sorted(by: { $0.idx < $1.idx })
        let deletions = results.filter({ !$0.isInsertion }).sorted(by: { $0.idx > $1.idx })
        self.results = deletions + insertions
    }

    public var insertions: [DiffStep<T>] {
        return results.filter({ $0.isInsertion })
    }
    public var deletions: [DiffStep<T>] {
        return results.filter({ !$0.isInsertion })
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

public func +<T> (left: Diff<T>, right: DiffStep<T>) -> Diff<T> {
    return Diff<T>(results: left.results + [right])
}

public func +<T> (left: DiffStep<T>, right: Diff<T>) -> Diff<T> {
    return Diff<T>(results: [left] + right.results)
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
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self, other, self.count, other.count, Diff<Element>(results: []))
    }

    /// Walks back through the generated table to generate the diff.
    fileprivate static func diffFromIndices(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int, _ currentResults: Diff<Element>) -> Diff<Element> {

        func diffFromIndicesInternal(
            _ table: [[Int]],
            _ x: [Element],
            _ y: [Element],
            _ i: Int,
            _ j: Int,
            _ currentResults: Diff<Element>
        ) -> Result<Diff<Element>> {
            if i == 0 && j == 0 {
                return .done(currentResults)
            }
            else {
                return .call {
                    if i == 0 {
                        return diffFromIndicesInternal(table, x, y, i, j-1, DiffStep.insert(j-1, y[j-1]) + currentResults)
                    } else if j == 0 {
                        return diffFromIndicesInternal(table, x, y, i - 1, j, DiffStep.delete(i-1, x[i-1]) + currentResults)
                    } else if table[i][j] == table[i][j-1] {
                        return diffFromIndicesInternal(table, x, y, i, j-1, DiffStep.insert(j-1, y[j-1]) + currentResults)
                    } else if table[i][j] == table[i-1][j] {
                        return diffFromIndicesInternal(table, x, y, i - 1, j, DiffStep.delete(i-1, x[i-1]) + currentResults)
                    } else {
                        return diffFromIndicesInternal(table, x, y, i-1, j-1, currentResults)
                    }
                }
            }
        }
        var result = diffFromIndicesInternal(table, x, y, i, j, Diff<Element>(results: []))
        while case .call(let f) = result {
            result = f()
        }
        if case let .done(accum) = result {
            return accum
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

public struct SectionedValues<S: Equatable, T: Equatable>: Equatable {
    public init(_ sectionsAndValues: [(S, [T])] = []) {
        self.sectionsAndValues = sectionsAndValues
    }
    public var sectionsAndValues: [(S, [T])]
    public var count: Int { return self.sectionsAndValues.count }
    public subscript(i: Int) -> (S, [T]) {
        return self.sectionsAndValues[i]
    }

    fileprivate var flattened: [SectionOrValue<S, T>] {
        return self.sectionsAndValues.enumerated().reduce([]) { accum, tuple in
            let x = SectionOrValue<S, T>.section(tuple.element.0)
            let values = tuple.element.1.map { SectionOrValue.value(tuple.element.0, $0) }
            return accum + values + [x]
        }
    }

    public func apply(_ diff: Diff2D<S, T>) -> SectionedValues<S, T> {
        // TODO this needs to change, because when a section is deleted, all its rows are deleted as well.
        // If that section is re-inserted later, it's not clear how to know to reinsert all the values as well.
        // Instead, we'll probably want to convert self to `flattened` here, apply each step in some kind of
        // 'flattened form', then unflatten.

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
        case .value(let _, let t):
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
        let flatL = lhs.flattened
        let flatR = rhs.flattened
        let diff = flatL.diff(flatR)
        var state = flatL
        let results: [DiffStep2D<S, T>] = diff.results.map { result in
            let transformed = Diff2D.build2DDiffStep(result: result, state: state)
            state.applyStep(result)
            return transformed
        }
        self.results = results.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (.delete(let s1, let r1, _), .delete(let s2, let r2, _)): return s1 > s2 || (s1 == s2 && r1 > r2)
            case (.delete, _): return true
            case (.sectionDelete(let s1, _), .sectionDelete(let s2, _)): return s1 > s2
            case (.sectionDelete, .sectionInsert): return true
            case (.sectionDelete, .insert): return true
            case (.sectionInsert(let s1, _), .sectionInsert(let s2, _)): return s1 < s2
            case (.sectionInsert, .insert): return true
            case (.insert(let s1, let r1, _), .insert(let s2, let r2, _)): return s1 < s2 || (s1 == s2 && r1 < r2)
            default: return false
            }
        }
        let _ = self.results
    }

    let lhs: SectionedValues<S, T>
    let rhs: SectionedValues<S, T>
    let results: [DiffStep2D<S, T>]

    private static func build2DDiffStep(result: DiffStep<SectionOrValue<S, T>>, state: [SectionOrValue<S, T>]) -> DiffStep2D<S, T> {
        func sectionAndRow(forIndex idx: Int) -> (Int, Int) {
            let totalSentinels = state.filter({ $0.isSection }).count
            var sentinelCount = 0
            for (i, raw) in state.reversed().enumerated() {
                let j = state.count - i
                if raw.isSection {
                    if j <= idx {
                        return ((totalSentinels - sentinelCount), idx - j)
                    } else {
                        sentinelCount += 1
                    }
                }
            }
            return (0, idx)
        }
        switch result {
        case .insert(let idx, let val):
            let (section, row) = sectionAndRow(forIndex: idx)
            switch val {
            case .section(let s):
                return DiffStep2D.sectionInsert(section, s)
            case .value(let _, let val):
                return DiffStep2D.insert(section, row, val)
            }
        case .delete(let idx, let val):
            let (section, row) = sectionAndRow(forIndex: idx)
            switch val {
            case .section(let s):
                return DiffStep2D.sectionDelete(section, s)
            case .value(let _, let val):
                return DiffStep2D.delete(section, row, val)
            }
        }
    }
//    init(_ steps: [DiffStep2D<S, T>]) {
//        self.steps = steps.sorted { lhs, rhs in
//            switch (lhs, rhs) {
//            case (.delete(let s1, let r1, _), .delete(let s2, let r2, _)): return s1 < s2 || r1 < r2
//            case (.delete, _): return true
//            case (.sectionDelete(let s1, _), .sectionDelete(let s2, _)): return s1 < s2
//            case (.sectionDelete, _): return true
//            case (.sectionInsert(let s1, _), .sectionInsert(let s2, _)): return s1 < s2
//            case (.sectionInsert, _): return true
//            case (.insert(let s1, let r1, _), .insert(let s2, let r2, _)): return s1 < s2 || r1 < r2
//            case (.insert, _): return true
//            }
//        }
//        let _ = self.steps
//        // TODO: remove unnecessary row deletions here (ones where the section will be deleted anyway)
////        let rowDeletions = steps.filter { step in
////            if case .delete = step { return true } else { return false }
////        }.sorted(by: { $0.idx < $1.idx })
////        let sectionDeletions = steps.filter { step in
////            if case .sectionDelete = step { return true } else { return false }
////        }
////        let sectionInsertions = steps.filter { step in
////            if case .sectionInsert = step { return true } else { return false }
////        }
////        let rowInsertions = steps.filter { step in
////            if case .insert = step { return true } else { return false }
////        }
////        self.steps = steps
//    }

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
