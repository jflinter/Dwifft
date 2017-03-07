//
//  DiffViewDiffCalculator.swift
//  Dwifft
//
//  Created by Sid on 07/03/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//
import Foundation

public protocol DiffableViewUpdater {
    func perform(operations: ViewOperationsType, animated: Bool, completion: @escaping () -> Void)
}

public protocol ViewOperationsType {
    var insertionIndexPaths: [IndexPath] { get }
    var deletionIndexPaths: [IndexPath] { get }
}

public class DiffViewDiffCalculator<T: Equatable> {
    private var lastRows: [[T]]
    private let viewUpdater: DiffableViewUpdater

    public init(viewUpdater: DiffableViewUpdater, initialRows: [[T]] = []) {
        self.viewUpdater = viewUpdater
        self.lastRows = initialRows
    }

    public func update(rows newRows: [[T]], animated: Bool, completion: @escaping () -> Void) {
        update(oldRows: lastRows, newRows: newRows, animated: animated, completion: completion)
        lastRows = newRows
    }

    private func update(oldRows: [[T]], newRows: [[T]], animated: Bool, completion: @escaping () -> Void) {
        assert(oldRows.count == newRows.count)

        let operations: ViewOperations<T> = ViewOperations()

        for index in 0..<oldRows.count {
            operations.update(at: index, oldRows: oldRows, newRows: newRows)
        }

        guard !operations.isEmpty else {
            completion()
            return
        }

        viewUpdater.perform(operations: operations, animated: animated, completion: completion)
    }
}

fileprivate class ViewOperations<T: Equatable>: ViewOperationsType {
    fileprivate(set) var insertionIndexPaths: [IndexPath]
    fileprivate(set) var deletionIndexPaths: [IndexPath]

    init() {
        insertionIndexPaths = []
        deletionIndexPaths = []
    }

    var isEmpty: Bool {
        return insertionIndexPaths.isEmpty && deletionIndexPaths.isEmpty
    }

    func update(at sectionIndex: Int, oldRows: [[T]], newRows: [[T]]) {
        let diff = oldRows[sectionIndex].diff(newRows[sectionIndex])

        guard !diff.results.isEmpty else {
            return
        }

        insertionIndexPaths.append(contentsOf: diff.insertions.map { step in
            return IndexPath(row: step.idx, section: sectionIndex)
        })

        deletionIndexPaths.append(contentsOf: diff.deletions.map { step in
            return IndexPath(row: step.idx, section: sectionIndex)
        })
    }
}
