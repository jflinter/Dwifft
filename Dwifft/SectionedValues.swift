//
//  SectionedValues.swift
//  Dwifft
//
//  Created by Jack Flintermann on 4/14/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

/// SectionedValues represents, well, a bunch of sections and their associated values.
/// You can think of it sort of like an "ordered dictionary", or an order of key-pairs.
/// If you are diffing a multidimensional structure of values (what might normally be,
/// for example, a 2D array), you will want to use this.
public struct SectionedValues<Section: Equatable, Value: Equatable>: Equatable {

    /// Initializes the struct with an array of key-pairs.
    ///
    /// - Parameter sectionsAndValues: An array of tuples. The first element in the tuple is
    /// the value of the section. The second element is an array of values to be associated with
    /// that section. Ordering matters, obviously. Note, it's totally ok if `sectionsAndValues`
    /// contains duplicate sections (or duplicate values within those sections).
    public init(_ sectionsAndValues: [(Section, [Value])] = []) {
        self.sectionsAndValues = sectionsAndValues
    }

    /// The underlying tuples contained in the receiver
    public let sectionsAndValues: [(Section, [Value])]

    internal var sections: [Section] { get { return self.sectionsAndValues.map { $0.0 } } }
    internal subscript(i: Int) -> (Section, [Value]) {
        return self.sectionsAndValues[i]
    }


    /// Returns a new SectionedValues appending a new key-value pair. I think this might be useful
    /// if you're building up a SectionedValues conditionally? (Well, I hope it is, anyway.)
    ///
    /// - Parameter sectionAndValue: the new key-value pair
    /// - Returns: a new SectionedValues containing the receiever's contents plus the new pair.
    public func appending(sectionAndValue: (Section, [Value])) -> SectionedValues<Section, Value> {
        return SectionedValues(self.sectionsAndValues + [sectionAndValue])
    }

    /// Compares two `SectionedValues` instances
    public static func ==(lhs: SectionedValues<Section, Value>, rhs: SectionedValues<Section, Value>) -> Bool {
        guard lhs.sectionsAndValues.count == rhs.sectionsAndValues.count else { return false }
        for i in 0..<(lhs.sectionsAndValues.count) {
            let ltuple = lhs.sectionsAndValues[i]
            let rtuple = rhs.sectionsAndValues[i]
            if (ltuple.0 != rtuple.0 || ltuple.1 != rtuple.1) {
                return false
            }
        }
        return true
    }
}

// MARK: - Custom grouping
public extension SectionedValues where Section: Hashable {

    /// This is a convenience initializer of sorts for `SectionedValues`. It acknowledges
    /// that sometimes you have an array of things that are naturally "groupable" - maybe
    /// a list of names in an address book, that can be grouped into their first initial,
    /// or a bunch of events that can be grouped into buckets of timestamps. This will handle
    /// clumping all of your values into the correct sections, and ordering everything correctly.
    ///
    /// - Parameters:
    ///   - values: All of the values that will end up in the `SectionedValues` you're making.
    ///   - valueToSection: A function that maps each value to the section it will inhabit.
    ///     In the above examples, this would take a name and return its first initial,
    ///     or take an event and return its bucketed timestamp.
    ///   - sortSections: A function that compares two sections, and returns true if the first
    ///     should be sorted before the second. Used to sort the sections in the returned `SectionedValues`.
    ///   - sortValues: A function that compares two values, and returns true if the first
    ///     should be sorted before the second. Used to sort the values in each section of the returned `SectionedValues`.
    public init(
        values: [Value],
        valueToSection: ((Value) -> Section),
        sortSections: ((Section, Section) -> Bool),
        sortValues: ((Value, Value) -> Bool)) {
        var dictionary = [Section: [Value]]()
        for value in values {
            let section = valueToSection(value)
            var current = dictionary[section] ?? []
            current.append(value)
            dictionary[section] = current
        }
        let sortedSections = dictionary.keys.sorted(by: sortSections)
        self.init(sortedSections.map { section in
            let values = dictionary[section] ?? []
            let sortedValues = values.sorted(by: sortValues)
            return (section, sortedValues)
        })
    }
    
}
