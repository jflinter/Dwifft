//
//  ExpectedAssertions.swift
//  Dwifft
//
//  Created by Alessandro on 06/04/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import Foundation
import XCTest

struct ExpectedAssertion<T: Equatable> {
    let expectation: XCTestExpectation
    let assertion: (_ expectedValue: T) -> Void
}

extension XCTestCase {
    func equalAssertions<T: Equatable>(for expectedValues: [T]) -> [ExpectedAssertion<T>] {
        var assertions: [ExpectedAssertion<T>] = []

        for values in expectedValues {
            let expected = values
            let assertionExpectation = expectation(description: "expected \(values)")
            let assertion = ExpectedAssertion<T>(expectation: assertionExpectation) { result in XCTAssertEqual(result, expected) }
            assertions.append(assertion)
        }

        return assertions
    }
}
