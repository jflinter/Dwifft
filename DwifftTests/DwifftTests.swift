//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import XCTest
import SwiftCheck

class DwifftSwiftCheckTests: XCTestCase {
    func testAll() {
        property("Diffing two arrays, then applying the diff to the first, yields the second") <- forAll { (a1 : ArrayOf<Int>, a2 : ArrayOf<Int>) in
            let diff = a1.getArray.diff(a2.getArray)
            return (a1.getArray.apply(diff) == a2.getArray) <?> "diff applies in forward order" ^&&^
                (a2.getArray.apply(diff.reversed()) == a1.getArray) <?> "diff applies in reverse order"
        }
    }
}

final class DwifftTests: XCTestCase {
    
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
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")
        }
    }

    func testDiffBenchmark() {
        let a: [Int] = (0...1000).map({ _ in Int(arc4random_uniform(100)) }).filter({ _ in arc4random_uniform(2) == 0})
        let b: [Int] = (0...1000).map({ _ in Int(arc4random_uniform(100)) }).filter({ _ in arc4random_uniform(2) == 0})
        measure {
            let _ = a.diff(b)
        }
    }
}
