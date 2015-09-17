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
    
    func testLCS() {
        
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
        
        let tests: [TestCase] = [
            TestCase("1234", "23", "23", "-0-3"),
            TestCase("0125890", "4598310", "590", "-0-1-2+0-4+3+4+5"),
            TestCase("BANANA", "KATANA", "AANA", "-0+0-2+2"),
            TestCase("1234", "1224533324", "1234", "+2+3+4+6+7+8"),
            TestCase("thisisatest", "testing123testing", "tsitest", "-1-2+1+3-5-6+5+6+7+8+9+14+15+16"),
            TestCase("HUMAN", "CHIMPANZEE", "HMAN", "+0-1+2+4+7+8+9"),
        ]
        
        for test in tests {

            XCTAssertEqual(LCS.calculate(test.array1, test.array2), test.expectedLCS, "incorrect LCS")
            
            let diff = Diff.calculate(test.array1, test.array2)
            let printableDiff = diff.map({ $0.debugDescription }).joinWithSeparator("")
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")
        }
        
    }
    
    func testArrayDiffCalculator() {
        
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
                let nsIndexPaths = indexPaths 
                for indexPath in nsIndexPaths {
                    self.insertionExpectations[indexPath.row]!.fulfill()
                }
            }
            
            private override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.Right, "incorrect insertion animation")
                let nsIndexPaths = indexPaths 
                for indexPath in nsIndexPaths {
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
    
}
