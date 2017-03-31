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
        return Diff(results: self.results.reversed().map({ $0.inverted }))
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

    fileprivate var inverted: DiffStep<T> {
        switch self {
        case .insert(let i, let j):
            return .delete(i, j)
        case .delete(let i, let j):
            return .insert(i, j)
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
        for result in diff.results {
            switch result {
            case .delete(let idx, _):
                copy.remove(at: idx)
            case .insert(let idx, let val):
                copy.insert(val, at: idx)
            }
        }
        return copy
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
