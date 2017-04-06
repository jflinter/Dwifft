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
        let expectedIndexesForInsertions = [0, 3, 4, 5]
        let expectedIndexesForDeletions = [4, 2, 1, 0]

        let tableView = TestTableView(insertionAssertions: assertions(for: expectedIndexesForInsertions),
                                      deletionAssertions: assertions(for: expectedIndexesForDeletions))
        let viewController = TestTableViewController(tableView: tableView, rows: [0, 1, 2, 5, 8, 9, 0])

        viewController.rows = [4, 5, 9, 8, 3, 1, 0]

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    private func assertions(for indexes: [Int]) -> [ExpectedAssertion<Int>] {
        var assertions: [ExpectedAssertion<Int>] = []

        for index in indexes {
            let expected = index
            let assertionExpectation = expectation(description: "expected \(index)")
            let assertion = ExpectedAssertion<Int>(expectation: assertionExpectation) { result in XCTAssertEqual(result, expected) }
            assertions.append(assertion)
        }

        return assertions
    }
}

final class TestTableView: UITableView {
    let insertionAssertions: [ExpectedAssertion<Int>]
    let deletionAssertions: [ExpectedAssertion<Int>]

    init(insertionAssertions: [ExpectedAssertion<Int>], deletionAssertions: [ExpectedAssertion<Int>]) {
        self.insertionAssertions = insertionAssertions
        self.deletionAssertions = deletionAssertions
        super.init(frame: .zero, style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        XCTAssertEqual(animation, .left, "incorrect insertion animation")

        indexPaths.enumerated().forEach { index, indexPath in
            let assertion = insertionAssertions[index]
            assertion.assertion(indexPath.item)
            assertion.expectation.fulfill()
        }
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        XCTAssertEqual(animation, .right, "incorrect insertion animation")

        indexPaths.enumerated().forEach { index, indexPath in
            let assertion = deletionAssertions[index]
            assertion.assertion(indexPath.item)
            assertion.expectation.fulfill()
        }
    }
}

final class TestTableViewController: UIViewController, UITableViewDataSource {
    let tableView: TestTableView
    let diffCalculator: TableViewDiffCalculator<Int>

    var rows: [Int] {
        didSet {
            diffCalculator.rows = rows
        }
    }

    init(tableView: TestTableView, rows: [Int]) {
        self.tableView = tableView
        self.diffCalculator = TableViewDiffCalculator<Int>(tableView: tableView, initialRows: rows)
        self.rows = rows
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func setup() {
        tableView.dataSource = self
        diffCalculator.insertionAnimation = .left
        diffCalculator.deletionAnimation = .right
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
