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
    
    static func randomArrayOfStuff() -> [String] {
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
    
    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .Plain, target: self, action: #selector(StuffTableViewController.shuffle))
    }
    
    @objc func shuffle() {
        self.stuff = StuffTableViewController.randomArrayOfStuff()
    }
    
    // MARK: - Dwifft stuff
    // This is the stuff that's relevant to actually using Dwifft. The rest is just boilerplate to get the app working.
    
    var diffCalculator: TableViewDiffCalculator<String>?
    
    var stuff: [String] = StuffTableViewController.randomArrayOfStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.rows = stuff
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.diffCalculator = TableViewDiffCalculator<String>(tableView: self.tableView, initialRows: self.stuff)
        
        // You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
        self.diffCalculator?.insertionAnimation = .Fade
        self.diffCalculator?.deletionAnimation = .Fade
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stuff.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        cell.textLabel?.text = self.stuff[indexPath.row]
        return cell
    }

}
