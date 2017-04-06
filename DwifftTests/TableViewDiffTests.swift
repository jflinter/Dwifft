//
//  TableViewDiffTests.swift
//  Dwifft
//
//  Created by Alessandro on 06/04/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit
import XCTest

final class TableViewDiffTests: XCTestCase {
    func testTableViewDiffCalculator() {

        class TestTableView: UITableView {

            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]

            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
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
                    self.insertionExpectations[(indexPath as NSIndexPath).row]!.fulfill()
                }
            }

            override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.right, "incorrect insertion animation")
                for indexPath in indexPaths {
                    self.deletionExpectations[(indexPath as NSIndexPath).row]!.fulfill()
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
                self.diffCalculator.insertionAnimation = .left
                self.diffCalculator.deletionAnimation = .right
                self.rows = rows
                super.init(nibName: nil, bundle: nil)
            }

            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }

            @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                return UITableViewCell()
            }

            @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return rows.count
            }

        }

        var insertionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            insertionExpectations[i] = x
        }

        var deletionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            deletionExpectations[i] = x
        }

        let tableView = TestTableView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(tableView: tableView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}
