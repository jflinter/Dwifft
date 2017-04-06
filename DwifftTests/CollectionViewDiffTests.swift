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
        let expectedIndexesForInsertions = [0, 3, 4, 5]
        let expectedIndexesForDeletions = [4, 2, 1, 0]

        let collectionView = TestCollectionView(insertionAssertions: equalAssertions(for: expectedIndexesForInsertions),
                                                deletionAssertions: equalAssertions(for: expectedIndexesForDeletions))
        let viewController = TestCollectionViewController(collectionView: collectionView, rows: [0, 1, 2, 5, 8, 9, 0])

        viewController.rows = [4, 5, 9, 8, 3, 1, 0]

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

final class TestCollectionView: UICollectionView {
    let insertionAssertions: [ExpectedAssertion<Int>]
    let deletionAssertions: [ExpectedAssertion<Int>]

    init(insertionAssertions: [ExpectedAssertion<Int>], deletionAssertions: [ExpectedAssertion<Int>]) {
        self.insertionAssertions = insertionAssertions
        self.deletionAssertions = deletionAssertions
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)

        indexPaths.enumerated().forEach { index, indexPath in
            let assertion = insertionAssertions[index]
            assertion.assertion(indexPath.item)
            assertion.expectation.fulfill()
        }
    }

    override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)

        indexPaths.enumerated().forEach { index, indexPath in
            let assertion = deletionAssertions[index]
            assertion.assertion(indexPath.item)
            assertion.expectation.fulfill()
        }
    }
}

final class TestCollectionViewController: UIViewController, UICollectionViewDataSource {
    let testCollectionView: TestCollectionView
    let diffCalculator: CollectionViewDiffCalculator<Int>

    var rows: [Int] {
        didSet {
            diffCalculator.rows = rows
        }
    }

    init(collectionView: TestCollectionView, rows: [Int]) {
        self.testCollectionView = collectionView
        self.diffCalculator = CollectionViewDiffCalculator<Int>(collectionView: collectionView, initialRows: rows)
        self.rows = rows
        super.init(nibName: nil, bundle: nil)
        setupCollectionView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func setupCollectionView() {
        testCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TestCell")
        testCollectionView.dataSource = self
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath)
    }
}
