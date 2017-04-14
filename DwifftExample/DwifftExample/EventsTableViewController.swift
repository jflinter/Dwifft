//
//  EventsTableViewController.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 4/14/17.
//  Copyright © 2017 jflinter. All rights reserved.
//

import UIKit
import Dwifft

// This class exists to show off how you can build common types of views (like, in this case, a simple event feed) using `SectionedValues`' "auto-grouping" initializer. (Now go read the comments for the `buttonPushes` variable.)

class EventsTableViewController: UITableViewController {

    let timeBuckets = [
        0: "Just now",
        5: "5 seconds ago",
        13: "13 seconds ago",
        60: "One whole minute ago",
        120: "Please go do something else",
    ]

    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    @IBAction func buttonPushed(_ sender: Any) {
        self.buttonPushes = self.buttonPushes + [Date()]
    }

    var diffCalculator: TableViewDiffCalculator<Int, Date>?

    // so, we can just store all our events ("button pushes" in this case) in an array. It doesn't even have to be sorted, because `Date` is `Comparable`. When it changes, we will update the `sectionedValues` property on our diff calculator. To do so, we will construct a SectionedValues by providing an array of values (`buttonPushes`) and a function by which to group them into sections (in this case, a simple function that picks a "time bucket" for each event. SectionedValues will then handle grouping & sorting all the values for us! 
    var buttonPushes: [Date] = [] {
        didSet {
            self.diffCalculator?.sectionedValues = SectionedValues<Int, Date>(values: buttonPushes, valueToSection: { buttonPush in
                let secondsBetween = Int(Date().timeIntervalSince(buttonPush))
                return timeBuckets.keys.sorted().filter({$0 <= secondsBetween}).last ?? 0
            }, sortSections: { $0 < $1 }, sortValues: { $0 < $1 })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView)
        self.buttonPushes = []

        // We'll just periodically force-trigger the `buttonPushes` setter to keep our list nice and timely.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.buttonPushes = self.buttonPushes
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.diffCalculator?.numberOfSections() ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.diffCalculator?.numberOfObjects(inSection: section) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let diffCalculator = self.diffCalculator else { return cell }
        let date = diffCalculator.value(atIndexPath: indexPath)
        cell.textLabel?.text = "Pushed at \(formatter.string(from: date))"
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let diffCalculator = self.diffCalculator else { return nil }
        let bucket = diffCalculator.value(forSection: section)
        return timeBuckets[bucket]
    }

}
