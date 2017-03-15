//
//  StuffTableViewController.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 8/23/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import Dwifft

class StuffTableViewController: UITableViewController {

    static let possibleStuff = [
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

    static func randomStuff() -> [(String, [String])] {
        var mutable = [(String, [String])]()
        for (key, values) in self.possibleStuff {
            let filtered = values.filter { _ in arc4random_uniform(2) == 0 }
            if !filtered.isEmpty { mutable.append((key, filtered)) }
        }
        return mutable
    }
    // I shamelessly stole this list of things from my friend Pasquale's blog post because I thought it was funny. You can see it at https://medium.com/elepath-exports/spatial-interfaces-886bccc5d1e9

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(StuffTableViewController.shuffle))
    }
    
    @objc func shuffle() {
        self.stuff = StuffTableViewController.randomStuff()
    }
    
    // MARK: - Dwifft stuff
    // This is the stuff that's relevant to actually using Dwifft. The rest is just boilerplate to get the app working.
    
    var diffCalculator: TableViewDiffCalculator<String, String>?
    
    var stuff: [(String, [String])] = StuffTableViewController.randomStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.rowsAndSections = stuff
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.diffCalculator = TableViewDiffCalculator<String, String>(tableView: self.tableView, initialRowsAndSections: [])
        
        // You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
        self.diffCalculator?.insertionAnimation = .fade
        self.diffCalculator?.deletionAnimation = .fade
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let diffCalculator = self.diffCalculator else { return 0 }
        return diffCalculator.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let diffCalculator = self.diffCalculator else { return 0 }
        return diffCalculator.numberOfRows(inSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = self.diffCalculator?.value(atIndexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.diffCalculator?.value(forSection: section)
    }

}
