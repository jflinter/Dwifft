[![Build Status](https://img.shields.io/travis/jflinter/Dwifft/master.svg)](https://travis-ci.org/jflinter/Dwifft)
![Current Version](https://img.shields.io/github/tag/jflinter/dwifft.svg?label=Current%20Version)

Dwifft!
===

In 10 seconds
---
Dwifft is a small Swift library that tells you what the "diff" is between two collections, namely, the series of "edit operations" required to turn one into the other. It also comes with UIKit bindings, to automatically, animatedly keep a UITableView/UICollectionView in sync with a piece of data by making the necessary row/section insertion/deletion calls for you as the data changes.

Longer version
---
Dwifft is a Swift library that does two things. The first thing sounds interesting but perhaps only abstractly useful, and the other thing is a very concretely useful thing based off the first thing.

The first thing (found in `Dwifft.swift`) is an algorithm that calculates the diff between two collections using the [Longest Common Subsequence method](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem). If this kind of thing is interesting to you, there's a pretty great paper on diffing algorithms: http://www.xmailserver.org/diff2.pdf

The second thing (found in `Dwifft+UIKit.swift`) is a series of diff calculators for `UITableView`s and `UICollectionView`s. Let's say you have a `UITableView` that's backed by a simple array of values (like a list of names, e.g. `["Alice", "Bob", "Carol"]`. If that array changes (maybe Bob leaves, and is replaced by Dave, so our list is now `["Alice, "Carol", "Dave"]`), we'll want to update the table. The easiest way to do this is by calling `reloadData` on it. This has a couple of downsides: the transition isn't animated, and it'll cause your user to lose their scroll position if they've scrolled the table. The nicer way is to use the `insertRowsAtIndexPaths:withRowAnimation` and `deleteRowsAtIndexPaths:withRowAnimation` methods on `UITableView`, but this requires you to figure out which index paths have changed in your array (in our example, you'd have to figure out that the row at index 1 should be removed, and a new row should be inserted at index 2 should then be added). If only we had a way to diff the previous value of our array with it's new value. Wait a minute.

When you wire up a `TableViewDiffCalculator` to your `UITableView` (or a `CollectionViewDiffCalculator` to your `UICollectionView`, it'll _automatically_ calculate diffs and trigger the necessary animations on it whenever you change its `sectionedValues` property. Neat, right? Notably, as of Dwifft 0.6, Dwifft will also figure out _section_ insertions and deletions, as well as how to efficiently insert and delete rows across different sections, which is just so massively useful if you have a multi-section table. If you're currently using a <0.6 version of Dwifft and want to do this, read the [0.6 release notes](https://github.com/jflinter/Dwifft/releases/tag/0.6).

Even longer version
---
Learn more about the history of Dwifft, and how it works, in this [exciting video of a talk](https://vimeo.com/211194798) recorded at the Brooklyn Swift meetup in March 2017.

Why you should use Dwifft
---
- Dwifft is *useful* - it can help you build a substantially better user experience if you have table/collection views with dynamic content in your app.
- Dwifft is *safe* - there is some non-trivial index math inside of this diff algorithm that is easy to screw up. Dwifft has 100% test coverage on all of its core algorithms. Additionally, all of Dwifft's core functionality is tested with [SwiftCheck](https://github.com/typelift/SwiftCheck), meaning it has been shown to behave correctly under an exhausting set of inputs and edge cases.
- Dwifft is *fast* - a lot of time has been spent making Dwifft considerably (many orders of magnitude) faster than a naïve implementation. It almost certainly won't be the bottleneck in your UI code.
- Dwifft is *small* - Dwifft believes (to the extent that a software library can "believe" in things) in the unix philosophy of small, easily-composed tools. It's unopinionated and flexible enough to fit into most apps, and leaves a lot of control in your hands as a developer. As such, you can probably cram it into your app in less than 5 minutes. Also, because it's small, it can actually achieve nice goals like 100% test and documentation coverage.

How to get started
---
- First, you should take a look at the example app, to get a feel for how Dwifft is meant to be used.
- Next, you should just sit down and read the [entire documentation](https://www.jackflintermann.com/Dwifft) - it will take you <10 minutes, and you'll leave knowing everything there is to know about Dwifft.
- Then, install Dwifft via cocoapods or carthage or whatever people are using these days.
- Then get to Dwiffing.

Contributing
---
Contributions are welcome, with some caveats - please read the [contributing guidelines](https://github.com/jflinter/Dwifft/blob/master/CONTRIBUTING.md) before opening a PR to avoid wasting both our time.

Ok, that's it, there's nothing more here.