//
//  CollectionViewDiffTests.swift
//  Dwifft
//
//  Created by Alessandro on 06/04/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit
import XCTest

final class CollectionViewDiffTests: XCTestCase {
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

                collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TestCell")
                collectionView.dataSource = self
            }

            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }

            @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return diffCalculator.rows.count
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
