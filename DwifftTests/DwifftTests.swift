//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import XCTest

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
            let printableDiff = diff.results.map({ $0.debugDescription }).joinWithSeparator("")
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")
            
            let applied = test.array1.apply(diff)
            XCTAssertEqual(applied, test.array2)
            
            let reversed = diff.reversed()
            let reverseApplied = test.array2.apply(reversed)
            XCTAssertEqual(reverseApplied, test.array1)
        }
        
        
    }
    
    func testTableViewDiffCalculator() {
        
        class TestTableView: UITableView {
            
            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]
            
            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
                self.insertionExpectations = insertionExpectations
                self.deletionExpectations = deletionExpectations
                super.init(frame: CGRectZero, style: UITableViewStyle.Plain)
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            private override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.Left, "incorrect insertion animation")
                for indexPath in indexPaths {
                    self.insertionExpectations[indexPath.row]!.fulfill()
                }
            }
            
            private override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.Right, "incorrect insertion animation")
                for indexPath in indexPaths {
                    self.deletionExpectations[indexPath.row]!.fulfill()
                }
            }
            
        }
        
        class TestViewController: UIViewController, UITableViewDataSource {
            
            let tableView: TestTableView
            let diffCalculator: TableViewDiffCalculator<Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rows = rows
                }
            }
            
            init(tableView: TestTableView, rows: [Int]) {
                self.tableView = tableView
                self.diffCalculator = TableViewDiffCalculator<Int>(tableView: tableView, initialRows: rows)
                self.diffCalculator.insertionAnimation = .Left
                self.diffCalculator.deletionAnimation = .Right
                self.rows = rows
                super.init(nibName: nil, bundle: nil)
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                return UITableViewCell()
            }
            
            @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return rows.count
            }
            
        }
        
        var insertionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectationWithDescription("+\(i)")
            insertionExpectations[i] = x
        }
        
        var deletionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectationWithDescription("+\(i)")
            deletionExpectations[i] = x
        }
        
        let tableView = TestTableView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(tableView: tableView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionViewDiffCalculator() {
        
        class TestCollectionView: UICollectionView {
            
            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]
            
            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
                self.insertionExpectations = insertionExpectations
                self.deletionExpectations = deletionExpectations
                super.init(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            private override func insertItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
                for indexPath in indexPaths {
                    self.insertionExpectations[indexPath.item]!.fulfill()
                }
            }
            
            private override func deleteItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
                for indexPath in indexPaths {
                    self.deletionExpectations[indexPath.item]!.fulfill()
                }
            }
            
        }
        
        class TestViewController: UIViewController, UICollectionViewDataSource {
            
            let testCollectionView: TestCollectionView
            let diffCalculator: CollectionViewDiffCalculator<Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rows = rows
                }
            }
            
            init(collectionView: TestCollectionView, rows: [Int]) {
                self.testCollectionView = collectionView
                self.diffCalculator = CollectionViewDiffCalculator<Int>(collectionView: self.testCollectionView, initialRows: rows)
                self.rows = rows
                super.init(nibName: nil, bundle: nil)
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return rows.count
            }
            
            @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
                return UICollectionViewCell()
            }
            
        }
        
        var insertionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectationWithDescription("+\(i)")
            insertionExpectations[i] = x
        }
        
        var deletionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectationWithDescription("+\(i)")
            deletionExpectations[i] = x
        }
        
        let collectionView = TestCollectionView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(collectionView: collectionView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
}
