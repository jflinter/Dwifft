//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import XCTest
import SwiftCheck

final class DwifftSwiftCheckTests: XCTestCase {
    func testAll() {
        property("Diffing two arrays, then applying the diff to the first, yields the second") <- forAll { (a1 : ArrayOf<Int>, a2 : ArrayOf<Int>) in
            let diff = a1.getArray.diff(a2.getArray)
            return (a1.getArray.apply(diff) == a2.getArray) <?> "diff applies in forward order" ^&&^
                (a2.getArray.apply(diff.reversed()) == a1.getArray) <?> "diff applies in reverse order"
        }
    }
}

final class DwifftTests: XCTestCase {
    let testCases = [TestCase(array1: "1234", array2: "23", expectedLCS: "23", expectedDiff: "-4@3-1@0"),
                     TestCase(array1: "0125890", array2: "4598310", expectedLCS: "590", expectedDiff: "-8@4-2@2-1@1-0@0+4@0+8@3+3@4+1@5"),
                     TestCase(array1: "BANANA", array2: "KATANA", expectedLCS: "AANA", expectedDiff: "-N@2-B@0+K@0+T@2"),
                     TestCase(array1: "1234", array2: "1224533324", expectedLCS: "1234", expectedDiff: "+2@2+4@3+5@4+3@6+3@7+2@8"),
                     TestCase(array1: "thisisatest", array2: "testing123testing", expectedLCS: "tsitest", expectedDiff: "-a@6-s@5-i@2-h@1+e@1+t@3+n@5+g@6+1@7+2@8+3@9+i@14+n@15+g@16"),
                     TestCase(array1: "HUMAN", array2: "CHIMPANZEE", expectedLCS: "HMAN", expectedDiff: "-U@1+C@0+I@2+P@4+Z@7+E@8+E@9")]

    func testThatLCSIsCalculatedCorrectly() {
        for testCase in testCases {
            XCTAssertEqual(testCase.array1.LCS(testCase.array2), testCase.expectedLCS, "incorrect LCS")
        }
    }

    func testThatDiffIsCreatedCorreclty() {
        for testCase in testCases {
            let diff = testCase.array1.diff(testCase.array2)
            let printableDiff = diff.results
                .map { $0.debugDescription }
                .joined(separator: "")

            XCTAssertEqual(printableDiff, testCase.expectedDiff, "incorrect diff")
        }
    }

    func testDiffBenchmark() {
        let a: [Int] = (0...1000)
            .map { _ in randomNumber(upTo: 100) }
            .filter { _ in randomNumber(upTo: 2) == 0}

        let b: [Int] = (0...1000)
            .map { _ in randomNumber(upTo: 100) }
            .filter { _ in randomNumber(upTo: 2) == 0}

        measure {
            let _ = a.diff(b)
        }
    }

    private func randomNumber(upTo bound: UInt32) -> Int {
        return Int(arc4random_uniform(bound))
    }
}

struct TestCase {
    let array1: [Character]
    let array2: [Character]
    let expectedLCS: [Character]
    let expectedDiff: String

    init(array1: String, array2: String, expectedLCS: String, expectedDiff: String) {
        self.array1 = Array(array1.characters)
        self.array2 = Array(array2.characters)
        self.expectedLCS = Array(expectedLCS.characters)
        self.expectedDiff = expectedDiff
    }
}
