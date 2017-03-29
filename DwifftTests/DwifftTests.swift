//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import XCTest
import SwiftCheck

struct ArbitraryOrderedLists {
    let lhs: SectionedValues<String, Int>
    let rhs: SectionedValues<String, Int>
}

extension ArbitraryOrderedLists : Arbitrary {
    static var arbitrary: Gen<ArbitraryOrderedLists> {
        typealias OrderedDict = DictionaryOf<String, ArrayOf<Int>>
        typealias OrderedDictsGen = Gen<(OrderedDict, OrderedDict)>
        return OrderedDictsGen.zip(OrderedDict.arbitrary, OrderedDict.arbitrary).map { (lhs, rhs) in
            let x = SectionedValues(lhs.getDictionary.map { ($0, $1.getArray) })
            let y = SectionedValues(rhs.getDictionary.map { ($0, $1.getArray) })
            return ArbitraryOrderedLists.init(lhs: x, rhs: y)
        }
    }

    static func shrink(_ lists: ArbitraryOrderedLists) -> [ArbitraryOrderedLists] {
        var shrinked: [ArbitraryOrderedLists] = []
        if lists.lhs.count > 0 {
            shrinked.append(ArbitraryOrderedLists(lhs: SectionedValues(Array(lists.lhs.sectionsAndValues.dropLast())), rhs: lists.rhs))
        }
        if lists.rhs.count > 0 {
            shrinked.append(ArbitraryOrderedLists(lhs: lists.lhs, rhs: SectionedValues(Array(lists.rhs.sectionsAndValues.dropLast()))))
        }
        return shrinked
    }
}

class DwifftSwiftCheckTests: XCTestCase {

    func testAll() {
        property("Diffing two arrays, then applying the diff to the first, yields the second") <- forAll { (a1 : ArrayOf<Int>, a2 : ArrayOf<Int>) in
            let diff = a1.getArray.diff(a2.getArray)
            let x = (a1.getArray.apply(diff) == a2.getArray) <?> "diff applies in forward order"
            let y = (a2.getArray.apply(diff.reversed()) == a1.getArray) <?> "diff applies in reverse order"
            return  x ^&&^ y
        }

        var i = 0
        let myProperty = forAllNoShrink(ArbitraryOrderedLists.arbitrary) { (a: ArbitraryOrderedLists) in
            print("iteration \(i)")
            i += 1
            let diff = Diff2D(lhs: a.lhs, rhs: a.rhs)
            let x = (a.lhs.apply(diff) == a.rhs) <?> "diff applies in forward order"
            return x
            //            let y = (a2.getArray.apply(diff.reversed()) == a1.getArray) <?> "diff applies in reverse order"
            //            return  x ^&&^ y
        }
        property("Diffing two 2D arrays, then applying the diff to the first, yields the second") <- myProperty
    }
}

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
            TestCase("1234", "23", "23", "-4@3-1@0"),
            TestCase("0125890", "4598310", "590", "-8@4-2@2-1@1-0@0+4@0+8@3+3@4+1@5"),
            TestCase("BANANA", "KATANA", "AANA", "-N@2-B@0+K@0+T@2"),
            TestCase("1234", "1224533324", "1234", "+2@2+4@3+5@4+3@6+3@7+2@8"),
            TestCase("thisisatest", "testing123testing", "tsitest", "-a@6-s@5-i@2-h@1+e@1+t@3+n@5+g@6+1@7+2@8+3@9+i@14+n@15+g@16"),
            TestCase("HUMAN", "CHIMPANZEE", "HMAN", "-U@1+C@0+I@2+P@4+Z@7+E@8+E@9"),
            ]

        for test in tests {

            XCTAssertEqual(test.array1.LCS(test.array2), test.expectedLCS, "incorrect LCS")

            let diff = test.array1.diff(test.array2)
            let printableDiff = diff.results.map({ $0.debugDescription }).joined(separator: "")
            if printableDiff != test.expectedDiff {
                print("bad")
            }
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")
        }


    }

    func test2D() {
        let testCases: [([(String, [Int])], [(String, [Int])], String)] = [
            (
                [("a", []), ("b", [])],
                [],
                "[ds(1), ds(0)]"
            ),
            (
                [],
                [("a", []), ("b", [])],
                "[is(0), is(1)]"
            ),
            (
                [],
                [],
                "[]"
            ),
            (
                [("a", [1]), ("b", []), ("c", [])],
                [("a", [1])],
                "[ds(2), ds(1)]"
            ),
            (
                [("a", []), ("b", [1]), ("c", [])],
                [("a", []), ("b", [2]), ("c", [])],
                "[d(1 0), i(1 0)]"
            ),
            (
                [("a", [1]), ("b", []), ("c", [])],
                [("a", []), ("b", [1]), ("c", [])],
                "[d(0 0), i(1 0)]"
            ),
            (
                [("a", [1]), ("b", []), ("c", [])],
                [("q", []), ("a", [1])],
                "[ds(2), ds(1), is(0)]"
            ),
            (
                [("a", [1]), ("b", []), ("c", [])],
                [("q", []), ("a", [1, 2])],
                "[ds(2), ds(1), is(0), i(1 1)]"
            ),
            (
                [("a", [1])],
                [("q", []), ("a", [1])],
                "[is(0)]"
            ),
            (
                [("a", [1, 2]), ("b", [3, 4])],
                [("a", [1, 2, 3, 4])],
                "[d(1 1), d(1 0), ds(1), i(0 2), i(0 3)]"
            ),
            (
                [("a", [1, 2, 3]), ("b", [4, 5]), ("c", [])],
                [("q", []), ("a", [1, 2]), ("b", [3, 4])],
                "[d(1 1), d(0 2), ds(2), is(0), i(2 0)]"
            ),
            ]
        for (lhs, rhs, expected) in testCases {
            let mappedLhs = SectionedValues(lhs.map { ($0, $1) })
            let mappedRhs = SectionedValues(rhs.map { ($0, $1) })
            XCTAssertEqual(Diff2D(lhs: mappedLhs, rhs: mappedRhs).results.debugDescription, expected)
        }
    }

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
            let diffCalculator: TableViewDiffCalculator<Int, Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rowsAndSections = SectionedValues([(0, rows)])
                }
            }

            init(tableView: TestTableView, rows: [Int]) {
                self.tableView = tableView
                self.diffCalculator = TableViewDiffCalculator<Int, Int>(tableView: tableView, initialRowsAndSections: SectionedValues([(0, rows)]))
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

            @objc func numberOfSections(in tableView: UITableView) -> Int {
                return self.diffCalculator.numberOfSections()
            }

            @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.diffCalculator.numberOfObjects(inSection: section)
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

    func testCollectionViewDiffCalculator() {

        class TestCollectionView: UICollectionView {

            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]

            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
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
                    self.insertionExpectations[(indexPath as NSIndexPath).item]!.fulfill()
                }
            }

            override func deleteItems(at indexPaths: [IndexPath]) {
                super.deleteItems(at: indexPaths)
                for indexPath in indexPaths {
                    self.deletionExpectations[(indexPath as NSIndexPath).item]!.fulfill()
                }
            }

        }

        class TestViewController: UIViewController, UICollectionViewDataSource {

            let testCollectionView: TestCollectionView
            let diffCalculator: CollectionViewDiffCalculator<Int, Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rowsAndSections = SectionedValues([(0, rows)])
                }
            }

            init(collectionView: TestCollectionView, rows: [Int]) {
                self.testCollectionView = collectionView
                self.diffCalculator = CollectionViewDiffCalculator<Int, Int>(collectionView: self.testCollectionView, initialRowsAndSections: SectionedValues([(0, rows)]))
                self.rows = rows
                super.init(nibName: nil, bundle: nil)

                collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TestCell")
                collectionView.dataSource = self
            }

            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }

            @objc func numberOfSections(in collectionView: UICollectionView) -> Int {
                return diffCalculator.numberOfSections()
            }

            @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return diffCalculator.numberOfObjects(inSection: section)
            }

            @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath)
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
        
        let collectionView = TestCollectionView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(collectionView: collectionView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}
