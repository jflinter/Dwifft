//
//  Stuff.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 3/30/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

import Foundation
import Dwifft

struct Stuff {

    // I shamelessly stole this list of things from my friend Pasquale's blog post because I thought it was funny. You can see it at https://medium.com/elepath-exports/spatial-interfaces-886bccc5d1e9
    static func wordStuff() -> SectionedValues<String, String> {
        let possibleStuff = [
            ("foods", [
                "Onions",
                "Pineapples",
                ]),
            ("animal-related", [
                "Cats",
                "A used lobster",
                "Fish legs",
                "Adam's apple",
                ]),
            ("muddy things", [
                "Mud",
                ]),
            ("other", [
                "Splinters",
                "Igloo cream",
                "Self-flying car"
                ])
        ]
        var mutable = [(String, [String])]()
        for (key, values) in possibleStuff {
            let filtered = values.filter { _ in arc4random_uniform(2) == 0 }
            if !filtered.isEmpty { mutable.append((key, filtered)) }
        }
        return SectionedValues(mutable)
    }

    static func onlyWordItems() -> [String] {
        return Stuff.wordStuff().sectionsAndValues.flatMap() { $0.1 }
    }

    static func emojiStuff() -> SectionedValues<String, String> {
        let possibleStuff = [
            ("foods", [
                "🍆",
                "🍑",
                "🌯",
                ]),
            ("animal-related", [
                "🐈",
                "🐙",
                "🦑",
                "🦍",
                ]),
            ("muddy things", [
                "💩",
                ]),
            ("other", [
                "🌚",
                "🌝",
                "🗿"
                ])
        ]
        var mutable = [(String, [String])]()
        for (key, values) in possibleStuff {
            let filtered = values.filter { _ in arc4random_uniform(2) == 0 }
            if !filtered.isEmpty { mutable.append((key, filtered)) }
        }
        return SectionedValues(mutable)
    }

}
