//
//  StuffTableViewController.swift
//  DwifftExample
//
//  Created by Jack Flintermann on 8/23/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import Dwifft

final class StuffTableViewController: UITableViewController {

    required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(StuffTableViewController.shuffle))
    }
    
    @objc func shuffle() {
        self.stuff = Stuff.wordStuff()
    }
    
    var diffCalculator: TableViewDiffCalculator<String, String>?
    
    var stuff: SectionedValues<String, String> = Stuff.wordStuff() {
        // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
        didSet {
            self.diffCalculator?.sectionedValues = stuff
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialSectionedValues: self.stuff)
        
        // You can change insertion/deletion animations like this! Automatic works for most situations. Fade works well too. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
        self.diffCalculator?.insertionAnimation = .fade
        self.diffCalculator?.deletionAnimation = .fade
    }

    // MARK: - Table view data source
    // diff calculators give you nice convenience methods to fill these out.

    /// IMPORTANT: you *must* implement `numberOfSections` this way (meaning, using this function on your diff calculator) in your app, to avoid a lot of gotchas around UITableView's internal assertions.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.diffCalculator?.numberOfSections() ?? 0
    }
    
    /// IMPORTANT: you *must* implement `numberOfSections` this way (meaning, using this function on your diff calculator) in your app, to avoid a lot of gotchas around UITableView's internal assertions.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.diffCalculator?.numberOfObjects(inSection: section) ?? 0
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
