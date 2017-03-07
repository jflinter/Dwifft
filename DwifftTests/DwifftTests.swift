//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import XCTest
@testable import Dwifft

class DwifftTests: XCTestCase {
    
    struct TestCase {
        let array1: [Character]
        let array2: [Character]
        let expectedLCS: [Character]
        let expectedDiff: String
        init(_ a: String, _ b: String, _ expected: String, _ expectedDiff: String) {
            self.array1 = Array(a.characters)
            self.array2 = Array(b.characters)
            self.expectedLCS = Array(expected.characters)
            self.expectedDiff = expectedDiff
        }
    }
    
    func testDiff() {
        let tests: [TestCase] = [
            TestCase("1234", "23", "23", "-1@0-4@3"),
            TestCase("0125890", "4598310", "590", "-0@0-1@1-2@2+4@0-8@4+8@3+3@4+1@5"),
            TestCase("BANANA", "KATANA", "AANA", "-B@0+K@0-N@2+T@2"),
            TestCase("1234", "1224533324", "1234", "+2@2+4@3+5@4+3@6+3@7+2@8"),
            TestCase("thisisatest", "testing123testing", "tsitest", "-h@1-i@2+e@1+t@3-s@5-a@6+n@5+g@6+1@7+2@8+3@9+i@14+n@15+g@16"),
            TestCase("HUMAN", "CHIMPANZEE", "HMAN", "+C@0-U@1+I@2+P@4+Z@7+E@8+E@9"),
        ]
        
        for test in tests {

            XCTAssertEqual(test.array1.LCS(test.array2), test.expectedLCS, "incorrect LCS")
            
            let diff = test.array1.diff(test.array2)
            let printableDiff = diff.results.map({ $0.debugDescription }).joined(separator: "")
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")
            
            let applied = test.array1.apply(diff)
            XCTAssertEqual(applied, test.array2)
            
            let reversed = diff.reversed()
            let reverseApplied = test.array2.apply(reversed)
            XCTAssertEqual(reverseApplied, test.array1)
        }
    }

    func testTableViewDiffCalculator() {
        var insertionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            insertionExpectations[IndexPath(row: i, section: 0)] = x
        }

        var deletionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            deletionExpectations[IndexPath(row: i, section: 0)] = x
        }

        let tableView = TestTableView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestTableViewController(tableView: tableView, row: [0, 1, 2, 5, 8, 9, 0])
        viewController.update(row: [4, 5, 9, 8, 3, 1, 0])
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testTableViewWithManySectionsDiffCalculator() {
        var insertionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i),0")
            insertionExpectations[IndexPath(row: i, section: 0)] = x
        }
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i),1")
            insertionExpectations[IndexPath(row: i, section: 1)] = x
        }


        var deletionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i),0")
            deletionExpectations[IndexPath(row: i, section: 0)] = x
        }
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i),1")
            deletionExpectations[IndexPath(row: i, section: 1)] = x
        }

        let tableView = TestTableView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestTableViewController(tableView: tableView, rows: [[0, 1, 2, 5, 8, 9, 0], [0, 1, 2, 5, 8, 9, 0]])
        viewController.update(rows: [[4, 5, 9, 8, 3, 1, 0], [4, 5, 9, 8, 3, 1, 0]])
        waitForExpectations(timeout: 1.0, handler: nil)
    }


    func testCollectionViewDiffCalculator() {
        var insertionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            insertionExpectations[IndexPath(item: i, section: 0)] = x
        }

        var deletionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            deletionExpectations[IndexPath(item: i, section: 0)] = x
        }
        
        let collectionView = TestCollectionView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestCollectionViewController(collectionView: collectionView, row: [0, 1, 2, 5, 8, 9, 0])
        viewController.update(row: [4, 5, 9, 8, 3, 1, 0])
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCollectionViewWithManySectionsDiffCalculator() {
        var insertionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i),0")
            insertionExpectations[IndexPath(item: i, section: 0)] = x
        }
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i),1")
            insertionExpectations[IndexPath(item: i, section: 1)] = x
        }

        var deletionExpectations: [IndexPath: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i),0")
            deletionExpectations[IndexPath(item: i, section: 0)] = x
        }
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i),1")
            deletionExpectations[IndexPath(item: i, section: 1)] = x
        }

        let collectionView = TestCollectionView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestCollectionViewController(collectionView: collectionView, rows: [[0, 1, 2, 5, 8, 9, 0], [0, 1, 2, 5, 8, 9, 0]])
        viewController.update(rows: [[4, 5, 9, 8, 3, 1, 0], [4, 5, 9, 8, 3, 1, 0]])
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

private class TestTableView: UITableView {

    let insertionExpectations: [IndexPath: XCTestExpectation]
    let deletionExpectations: [IndexPath: XCTestExpectation]

    init(insertionExpectations: [IndexPath: XCTestExpectation], deletionExpectations: [IndexPath: XCTestExpectation]) {
        self.insertionExpectations = insertionExpectations
        self.deletionExpectations = deletionExpectations
        super.init(frame: CGRect.zero, style: UITableViewStyle.plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        XCTAssertEqual(animation, UITableViewRowAnimation.left, "incorrect insertion animation")
        for indexPath in indexPaths {
            self.insertionExpectations[indexPath]!.fulfill()
        }
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        XCTAssertEqual(animation, UITableViewRowAnimation.right, "incorrect insertion animation")
        for indexPath in indexPaths {
            self.deletionExpectations[indexPath]!.fulfill()
        }
    }

}

private class TestTableViewController: UIViewController, UITableViewDataSource {

    let tableView: TestTableView
    let diffCalculator: DiffViewDiffCalculator<Int>
    private var rows: [[Int]]

    func update(rows: [[Int]]) {
        diffCalculator.update(rows: rows, animated: true) {
            self.rows = rows
        }
    }

    func update(row: [Int]) {
        update(rows: [row])
    }

    init(tableView: TestTableView, rows: [[Int]]) {
        self.tableView = tableView
        self.diffCalculator = DiffViewDiffCalculator(
            viewUpdater: TableViewUpdater(
                tableView: tableView,
                insertionAnimation: .left,
                deletionAnimation: .right
            ),
            initialRows: rows
        )
        self.rows = rows
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(tableView: TestTableView, row: [Int]) {
        self.init(tableView: tableView, rows: [row])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }
}

private class TestCollectionView: UICollectionView {

    let insertionExpectations: [IndexPath: XCTestExpectation]
    let deletionExpectations: [IndexPath: XCTestExpectation]

    init(insertionExpectations: [IndexPath: XCTestExpectation], deletionExpectations: [IndexPath: XCTestExpectation]) {
        self.insertionExpectations = insertionExpectations
        self.deletionExpectations = deletionExpectations
        super.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)
        for indexPath in indexPaths {
            self.insertionExpectations[indexPath]!.fulfill()
        }
    }

    override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)
        for indexPath in indexPaths {
            self.deletionExpectations[indexPath]!.fulfill()
        }
    }

}

private class TestCollectionViewController: UIViewController, UICollectionViewDataSource {

    let testCollectionView: TestCollectionView
    let diffCalculator: DiffViewDiffCalculator<Int>
    private var rows: [[Int]]

    func update(row: [Int]) {
        update(rows: [row])
    }

    func update(rows: [[Int]]) {
        diffCalculator.update(rows: rows, animated: true) {
            self.rows = rows
        }
    }

    convenience init(collectionView: TestCollectionView, row: [Int]) {
        self.init(collectionView: collectionView, rows: [row])
    }

    init(collectionView: TestCollectionView, rows: [[Int]]) {
        self.testCollectionView = collectionView
        self.diffCalculator = DiffViewDiffCalculator(
            viewUpdater: CollectionViewUpdater(
                collectionView: collectionView
            ),
            initialRows: rows
        )
        self.rows = rows
        super.init(nibName: nil, bundle: nil)

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TestCell")
        collectionView.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows[section].count
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath)
    }

    @objc func numberOfSections(in collectionView: UICollectionView) -> Int {
        return rows.count
    }
}
