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
        self.results = results.sorted { lhs, rhs in
            if !lhs.isInsertion && !rhs.isInsertion {
                return lhs.idx > rhs.idx
            }
            else if lhs.isInsertion {
                return false
            } else if rhs.isInsertion {
                return true
            } else {
                return lhs.idx < rhs.idx
            }
        }
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

public extension Array where Element: Equatable {

    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(_ other: [Element]) -> Diff<Element> {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self, other, self.count, other.count)
    }

    /// Walks back through the generated table to generate the diff.
    fileprivate static func diffFromIndices(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {
        if i == 0 && j == 0 {
            return Diff<Element>(results: [])
        } else if i == 0 {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
        } else if j == 0 {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
        } else {
            return diffFromIndices(table, x, y, i-1, j-1)
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
// TODO move

enum ValOrSentinel<S: Equatable, T: Equatable>: CustomDebugStringConvertible, Equatable {
    case val(T)
    case sentinel(S)
    init(_ val: T) {
        self = .val(val)
    }
    init(_ val: S) {
        self = .sentinel(val)
    }

    public var isSentinel: Bool {
        switch self {
            case .sentinel: return true
            default: return false
        }
    }

    public var debugDescription: String {
        switch self {
        case .sentinel:
            return ","
        case .val(let t):
            if let x = t as? Int {
                return "\(x)"
            }
            return "?"
        }
    }
}

func ==<S, T>(lhs: ValOrSentinel<S, T>, rhs: ValOrSentinel<S, T>) -> Bool {
    switch lhs {
    case .sentinel(let l):
        if case .sentinel(let r) = rhs, l == r {
            return true
        }
    case .val(let l):
        if case .val(let r) = rhs, l == r {
            return true
        }
    }
    return false
}

struct Diff2D<S, T>: CustomDebugStringConvertible {
    let steps: [DiffStep2D<S, T>]

    public var debugDescription: String {
        return "[" + self.steps.map { $0.debugDescription }.joined(separator: ", ") + "]"
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

public struct ArrayDiff2D<S: Equatable, T: Equatable> {

    init(lhs: [(S, [T])], rhs: [(S, [T])]) {
        self.lhs = lhs
        self.rhs = rhs
        let flatL = ArrayDiff2D.flattenedArray(fromArray: self.lhs)
        let flatR = ArrayDiff2D.flattenedArray(fromArray: self.rhs)
        let diff = flatL.diff(flatR)
        var state = flatL
        self.results = diff.results.map { result in
            let transformed = ArrayDiff2D.build2DDiffStep(result: result, state: state)
            state.applyStep(result)
            return transformed
        }
    }
    
    let lhs: [(S, [T])]
    let rhs: [(S, [T])]
    let results: [DiffStep2D<S, T>]

    static func flattenedArray(fromArray: [(S, [T])]) -> [ValOrSentinel<S, T>] {
        return fromArray.enumerated().reduce([]) { accum, tuple in
            let x = ValOrSentinel<S, T>.sentinel(tuple.element.0)
            return accum + tuple.element.1.map(ValOrSentinel.init) + [x]
        }
    }

    static func build2DDiffStep(result: DiffStep<ValOrSentinel<S, T>>, state: [ValOrSentinel<S, T>]) -> DiffStep2D<S, T> {
        func sectionAndRow(forIndex idx: Int) -> (Int, Int) {
            let totalSentinels = state.filter({ $0.isSentinel }).count
            var sentinelCount = 0
            for (i, raw) in state.reversed().enumerated() {
                let j = state.count - i
                if raw.isSentinel {
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
            case .sentinel(let s):
                return DiffStep2D.sectionInsert(section, s)
            case .val(let val):
                return DiffStep2D.insert(section, row, val)
            }
        case .delete(let idx, let val):
            let (section, row) = sectionAndRow(forIndex: idx)
            switch val {
            case .sentinel(let s):
                return DiffStep2D.sectionDelete(section, s)
            case .val(let val):
                return DiffStep2D.delete(section, row, val)
            }
        }
    }
}



