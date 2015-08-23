//
//  LCS.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit


enum ArrayDiffResult : DebugPrintable {
    case Insert(Int)
    case Delete(Int)
    var isInsertion: Bool {
        switch(self) {
        case .Insert(let i):
            return true
        case .Delete(let i):
            return false
        }
    }
    var debugDescription: String {
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

struct LCS<T: Equatable> {
    
    private let x, y : [T]
    private let n, m : Int
    private var table : [[Int]]
    
    init(_ x: [T], _ y: [T]) {
        self.x = x
        self.y = y
        self.n = x.count
        self.m = y.count
        self.table = Array(count: self.n + 1, repeatedValue: Array(count: self.m + 1, repeatedValue: 0))
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
    }
    
    func lcs() -> [T] {
        return LCSFromIndices(n, j: m)
    }
    
    func diff() -> [ArrayDiffResult] {
        return diffFromIndices(n, j: m)
    }
    
    private func LCSFromIndices(i: Int, j: Int) -> [T] {
        if i == 0 && j == 0 {
            return []
        } else if i == 0 {
            return LCSFromIndices(i, j: j - 1)
        } else if j == 0 {
            return LCSFromIndices(i - 1, j: j)
        } else if x[i-1] == y[j-1] {
            return LCSFromIndices(i - 1, j: j - 1) + [x[i - 1]]
        } else if table[i-1][j] > table[i][j-1] {
            return LCSFromIndices(i-1, j: j)
        } else {
            return LCSFromIndices(i, j: j-1)
        }
    }
    
    private func diffFromIndices(i: Int, j: Int) -> [ArrayDiffResult] {
        if i == 0 && j == 0 {
            return []
        } else if i == 0 {
            return diffFromIndices(i, j: j-1) + [ArrayDiffResult.Insert(j-1)]
        } else if j == 0 {
            return diffFromIndices(i - 1, j: j) + [ArrayDiffResult.Delete(i-1)]
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(i, j: j-1) + [ArrayDiffResult.Insert(j-1)]
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(i - 1, j: j) + [ArrayDiffResult.Delete(i-1)]
        } else {
            return diffFromIndices(i-1, j: j-1)
        }
    }
    
}
