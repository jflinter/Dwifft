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

    fileprivate lazy var dataSource: StuffDataSouce = {
        return StuffDataSouce(
            sections: 2,
            viewUpdater: TableViewUpdater(
                tableView: self.tableView,
                insertionAnimation: .fade,
                deletionAnimation: .fade
            )
        )
    }()

    @objc func onShuffle() {
        dataSource.shuffle(animated: true)
    }

    @objc func onDismiss() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(onShuffle))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onDismiss))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        dataSource.shuffle(animated: false)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfStuff(in: section)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfStuffs
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section: \(section)"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = dataSource.stuff(section: indexPath.section, row: indexPath.row)
        return cell
    }
}
