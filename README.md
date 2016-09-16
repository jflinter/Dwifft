[![Build Status](https://travis-ci.org/jflinter/Dwifft.svg?branch=master)](https://travis-ci.org/jflinter/Dwifft)
![Current Version](https://img.shields.io/github/tag/jflinter/dwifft.svg?label=Current Version)


Dwifft!
===

OK. Dwifft is a Swift library that does two things. The first thing sounds interesting but perhaps only abstractly useful, and the other thing is a very concretely useful thing based off the first thing.

The first thing (found in `Dwifft.swift`) is an algorithm that solves the [Longest Common Subsequence problem](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem). Pragmatically, the problem of finding the difference between two arrays is trivially reducable to the LCS problem, i.e. if you can find the longest common subsequence between two arrays, you've also found a series of transforms to apply to array 1 that will result in array 2. This algorithm is written purely in Swift, and uses dynamic programming to achieve substantial performance improvements over a naïve approach (that being said, there are several ways it could probably be sped up.) Perhaps by now you've figured out that Dwifft is a terrible/brilliant portmanteau of "Swift" and "Diff". If this kind of thing is interesting to you, there's a pretty great paper on diffing algorithms: http://www.xmailserver.org/diff2.pdf

The second thing (found in `Dwifft+UIKit.swift`) is a series of diff calculators for `UITableView`s and `UICollectionView`s. Let's say you have a `UITableView` that's backed by a simple array of values (like a list of names, e.g. `["Alice", "Bob", "Carol"]`. If that array changes (maybe Bob leaves, and is replaced by Dave, so our list is now `["Alice, "Carol", "Dave"]`), we'll want to update the table. The easiest way to do this is by calling `reloadData` on it. This has a couple of downsides: the transition isn't animated, and it'll cause your user to lose their scroll position if they've scrolled the table. The nicer way is to use the `insertRowsAtIndexPaths:withRowAnimation` and `deleteRowsAtIndexPaths:withRowAnimation` methods on `UITableView`, but this requires you to figure out which index paths have changed in your array (in our example, you'd have to figure out that the row at index 1 should be removed, and a new row should be inserted at index 2 should then be added). If only we had a way to diff the previous value of our array with it's new value. Wait a minute.

When you wire up a `TableViewDiffCalculator` to your `UITableView` (or a `CollectionViewDiffCalculator` to your `UICollectionView`, it'll _automatically_ calculate diffs and trigger the necessary animations on it whenever you change its `rows` property. Neat, right? Usually, this `rows` object will be the same thing you're using in your `UITableViewDataSource` methods. The only constraint is that the items in that `rows` array have to conform to `Equatable`, because, you know, how else could you compare them?

This makes slightly more sense in code, so check out the tests (which show `LCS`/`Diff` in action) and the example app (which demonstrates the use of `TableViewDiffCalculator` if you're interested! You can quickly run the example with `pod try Dwifft`.

Thanks for reading! PRs and such are of course welcome, but I want to keep this pretty tightly-scoped, so I'd politely request you open an issue before going off and implementing any new functionality so we can talk things over first.

Happy dwiffing!

Oh right, how to install
---

Cocoapods or Carthage. You'll need to use cocoapods frameworks because Swift. Version 0.1 is written in Swift 1.2, versions 0.2-0.3.1 are Swift 2, beyond that is Swift 3.

A fun gif
---

<img src="dwifft.gif" alt="Dwifft" style="width: 375px !important;"/>
