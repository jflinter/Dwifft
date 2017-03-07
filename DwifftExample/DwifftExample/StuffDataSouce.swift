//
//  StuffDataSouce.swift
//  DwifftExample
//
//  Created by Sid on 07/03/2017.
//  Copyright © 2017 jflinter. All rights reserved.
//

import Foundation
import Dwifft

class StuffDataSouce {
    private let possibleStuff = [
        "Cats",
        "Onions",
        "A used lobster",
        "Splinters",
        "Mud",
        "Pineapples",
        "Fish legs",
        "Adam's apple",
        "Igloo cream",
        "Self-flying car"
    ]
    // I shamelessly stole this list of things from my friend Pasquale's blog post because I thought it was funny. You can see it at https://medium.com/elepath-exports/spatial-interfaces-886bccc5d1e9

    private var randomArrayOfStuff: [String] {
        var possibleStuff = self.possibleStuff
        for i in 0..<possibleStuff.count - 1 {
            let j = Int(arc4random_uniform(UInt32(possibleStuff.count - i))) + i
            if i != j {
                swap(&possibleStuff[i], &possibleStuff[j])
            }
        }
        let subsetCount: Int = Int(arc4random_uniform(3)) + 5
        return Array(possibleStuff[0...subsetCount])
    }

    private func randomArrayOfStuffs(count: Int) -> [[String]] {
        return (0..<count).map { _ in
            randomArrayOfStuff
        }
    }

    fileprivate var stuffs: [[String]]
    fileprivate let sections: Int
    fileprivate let viewUpdater: DiffableViewUpdater

    private lazy var diffCalculator: DiffViewDiffCalculator<String> = {
        return DiffViewDiffCalculator(
            viewUpdater: self.viewUpdater,
            initialRows: self.stuffs
        )
    }()

    init(sections: Int, viewUpdater: DiffableViewUpdater) {
        self.sections = sections
        self.stuffs = Array(repeating: [], count: sections)
        self.viewUpdater = viewUpdater
    }

    func shuffle(animated: Bool) {
        let newStuffs = randomArrayOfStuffs(count: sections)
        update(stuffs: newStuffs, animated: animated)
    }

    private func update(stuffs: [[String]], animated: Bool) {
        diffCalculator.update(rows: stuffs, animated: animated) { [weak self] in
            self?.stuffs = stuffs
        }
    }

    var numberOfStuffs: Int {
        return stuffs.count
    }

    func numberOfStuff(in section: Int) -> Int {
        return stuffs[section].count
    }

    func stuff(section: Int, row: Int) -> String {
        return stuffs[section][row]
    }
}
