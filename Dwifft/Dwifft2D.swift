//
//  Dwifft2D.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/29/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

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
            tmp.applyStep(step: result)
        }
        return tmp
    }

    public mutating func applyStep(step: DiffStep2D<S, T>) {
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

public struct Diff2D<S: Equatable, T: Equatable>: CustomDebugStringConvertible {
    public static func diff(lhs: SectionedValues<S, T>, rhs: SectionedValues<S, T>) -> Diff2D {
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
        lhs: SectionedValues<S, T>,
        rhs: SectionedValues<S, T>,
        sectionDeletions: [DiffStep2D<S, T>],
        sectionInsertions: [DiffStep2D<S, T>],
        deletions: [DiffStep2D<S, T>],
        insertions: [DiffStep2D<S, T>]
    ) {
        self.lhs = lhs
        self.rhs = rhs
        self.sectionDeletions = sectionDeletions
        self.sectionInsertions = sectionInsertions
        self.deletions = deletions
        self.insertions = insertions
        self.results = sectionDeletions + sectionInsertions + deletions + insertions
    }

    private let lhs: SectionedValues<S, T>
    private let rhs: SectionedValues<S, T>
    let results: [DiffStep2D<S, T>]
    let insertions: [DiffStep2D<S, T>]
    let deletions: [DiffStep2D<S, T>]
    let sectionInsertions: [DiffStep2D<S, T>]
    let sectionDeletions: [DiffStep2D<S, T>]

    public func reversed() -> Diff2D<S, T> {
        return Diff2D.diff(lhs: self.rhs, rhs: self.lhs)
    }

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
            return DiffResults<S, T>(
                insertions: insertions,
                deletions: deletions,
                sectionInsertions: [],
                sectionDeletions: []
            )

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

            let middle = SectionedValues(middleSectionsAndValues)
            let rowResults = Diff2D.buildResults(middle, rhs)

            return DiffResults<S, T>(
                insertions: rowResults.insertions,
                deletions: rowResults.deletions,
                sectionInsertions: sectionInsertions,
                sectionDeletions: sectionDeletions
            )
        }
    }

    public var debugDescription: String {
        return "[" + self.results.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

public enum DiffStep2D<S, T>: CustomDebugStringConvertible {
    case insert(Int, Int, T)
    case delete(Int, Int, T)
    case sectionInsert(Int, S)
    case sectionDelete(Int, S)

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

    fileprivate var inverted: DiffStep2D<S, T> {
        switch self {
        case .insert(let s, let i, let j): return .delete(s, i, j)
        case .delete(let s, let i, let j): return .insert(s, i, j)
        case .sectionInsert(let s, let i): return .sectionDelete(s, i)
        case .sectionDelete(let s, let i): return .sectionInsert(s, i)
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
