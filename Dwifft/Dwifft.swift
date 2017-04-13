//
//  Dwifft.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

/// These get returned from calls to Dwifft.diff(). They represent insertions or deletions
/// that need to happen to transform one array into another.
public enum DiffStep<Value> : CustomDebugStringConvertible {
    case insert(Int, Value)
    case delete(Int, Value)

    public var debugDescription: String {
        switch(self) {
        case let .insert(i, j):
            return "+\(j)@\(i)"
        case let .delete(i, j):
            return "-\(j)@\(i)"
        }
    }
    public var idx: Int {
        switch(self) {
        case let .insert(i, _):
            return i
        case let .delete(i, _):
            return i
        }
    }
    public var value: Value {
        switch(self) {
        case let .insert(j):
            return j.1
        case let .delete(j):
            return j.1
        }
    }
}

private enum Result<T>{
    case done(T)
    case call(() -> Result<T>)
}

public struct Dwifft {

    /// Returns the sequence of `DiffStep`s required to transform one array into another.
    ///
    /// - Parameters:
    ///   - lhs: an array
    ///   - rhs: another, uh, array
    /// - Returns: the series of transformations that, when applied to `lhs`, will yield `lhs`.
    public static func diff<Value: Equatable>(lhs: [Value], rhs: [Value]) -> [DiffStep<Value>] {
        if lhs.isEmpty {
            return rhs.enumerated().map(DiffStep.insert)
        } else if rhs.isEmpty {
            return lhs.enumerated().map(DiffStep.delete).reversed()
        }

        let table = MemoizedSequenceComparison.buildTable(lhs, rhs, lhs.count, rhs.count)
        var result = diffInternal(table, lhs, rhs, lhs.count, rhs.count, ([], []))
        while case let .call(f) = result {
            result = f()
        }
        if case let .done(accum) = result {
            return accum.1 + accum.0
        } else {
            fatalError("unreachable code")
        }
    }

    /// Applies a diff to an array. The following should always be true:
    /// Given x: [T], y: [T], Dwifft.apply(Dwifft.diff(lhs: x, rhs: y), toArray: x) == y
    public static func apply<Value>(diff: [DiffStep<Value>], toArray lhs: [Value]) -> [Value] {
        var copy = lhs
        for result in diff {
            switch result {
            case let .delete(idx, _):
                copy.remove(at: idx)
            case let .insert(idx, val):
                copy.insert(val, at: idx)
            }
        }
        return copy
    }

    private static func diffInternal<Value: Equatable>(
        _ table: [[Int]],
        _ x: [Value],
        _ y: [Value],
        _ i: Int,
        _ j: Int,
        _ currentResults: ([DiffStep<Value>], [DiffStep<Value>])
        ) -> Result<([DiffStep<Value>], [DiffStep<Value>])> {
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
}


fileprivate struct MemoizedSequenceComparison<T: Equatable> {
    static func buildTable(_ x: [T], _ y: [T], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        // using unsafe pointers lets us avoid swift array bounds-checking, which results in a considerable speed boost.
        table.withUnsafeMutableBufferPointer { unsafeTable in
            x.withUnsafeBufferPointer { unsafeX in
                y.withUnsafeBufferPointer { unsafeY in
                    for i in 1...n {
                        for j in 1...m {
                            if unsafeX[i&-1] == unsafeY[j&-1] {
                                unsafeTable[i][j] = unsafeTable[i&-1][j&-1] + 1
                            } else {
                                unsafeTable[i][j] = max(unsafeTable[i&-1][j], unsafeTable[i][j&-1])
                            }
                        }
                    }

                }
            }
        }
        return table
    }
}

public extension Array where Element: Equatable {

    @available(*, deprecated)
    /// Deprecated in favor of `Dwifft.diff`.
    public func diff(_ other: [Element]) -> [DiffStep<Element>] {
        return Dwifft.diff(lhs: self, rhs: other)
    }

    @available(*, deprecated)
    /// Deprecated in favor of `Dwifft.apply`.
    public func apply(_ diff: [DiffStep<Element>]) -> [Element] {
        return Dwifft.apply(diff: diff, toArray: self)
    }

}
