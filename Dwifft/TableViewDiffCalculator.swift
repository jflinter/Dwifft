//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

import UIKit

public class TableViewDiffCalculator<T: Equatable> {
    public weak var tableView: UITableView?
    
    public init(tableView: UITableView, initialRows: [T] = []) {
        self.tableView = tableView
        self.rows = initialRows
    }
    public var sectionIndex: Int = 0
    public var insertionAnimation = UITableViewRowAnimation.Automatic
    public var deletionAnimation = UITableViewRowAnimation.Automatic
    public var rows : [T] {
        didSet {
            let oldRows = oldValue
            let newRows = self.rows
            let changes = LCS(oldRows, newRows).diff()
            if (changes.count > 0) {
                tableView?.beginUpdates()
                for change in changes {
                    switch(change) {
                    case .Insert(let idx):
                        tableView?.insertRowsAtIndexPaths([NSIndexPath(forRow: idx, inSection: sectionIndex)], withRowAnimation: insertionAnimation)
                    case .Delete(let idx):
                        tableView?.deleteRowsAtIndexPaths([NSIndexPath(forRow: idx, inSection: sectionIndex)], withRowAnimation: deletionAnimation)
                    }
                }
                tableView?.endUpdates()

            }
        }
    }
    
}
