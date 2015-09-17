//
//  LCS.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

/// These get returned from calls to Array.diff(). They represent insertions or deletions that need to happen to transform array a into array b.
public enum ArrayDiffResult : CustomDebugStringConvertible {
    case Insert(Int)
    case Delete(Int)
    var isInsertion: Bool {
        switch(self) {
        case .Insert:
            return true
        case .Delete:
            return false
        }
    }
    public var debugDescription: String {
        switch(self) {
        case .Insert(let i):
            return "+\(i)"
        case .Delete(let i):
            return "-\(i)"
        }
    }
    var idx: Int {
        switch(self) {
        case .Insert(let i):
            return i
        case .Delete(let i):
            return i
        }
    }
}

public extension Array where Element: Equatable {
    
    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(other: [Element]) -> [ArrayDiffResult] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the diff.
    private static func diffFromIndices(table: [[Int]], _ i: Int, _ j: Int) -> [ArrayDiffResult] {
        if i == 0 && j == 0 {
            return []
        } else if i == 0 {
            return diffFromIndices(table, i, j-1) + [ArrayDiffResult.Insert(j-1)]
        } else if j == 0 {
            return diffFromIndices(table, i - 1, j) + [ArrayDiffResult.Delete(i-1)]
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(table, i, j-1) + [ArrayDiffResult.Insert(j-1)]
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(table, i - 1, j) + [ArrayDiffResult.Delete(i-1)]
        } else {
            return diffFromIndices(table, i-1, j-1)
        }
    }
    
}

public extension Array where Element: Equatable {
    
    /// Returns the longest common subsequence between two arrays.
    public func LCS(other: [Element]) -> [Element] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.lcsFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the LCS.
    private static func lcsFromIndices(table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
        if i == 0 && j == 0 {
            return []
        } else if i == 0 {
            return lcsFromIndices(table, x, y, i, j - 1)
        } else if j == 0 {
            return lcsFromIndices(table, x, y, i - 1, j)
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
    static func buildTable(x: [T], _ y: [T], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(count: n + 1, repeatedValue: Array(count: m + 1, repeatedValue: 0))
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
