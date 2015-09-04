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
    
    /// Right now this only works on a single section of a tableView. If your tableView has multiple sections, though, you can just use multiple TableViewDiffCalculators, one per section, and set this value appropriately on each one.
    public var sectionIndex: Int = 0
    
    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.Automatic, deletionAnimation = UITableViewRowAnimation.Automatic
    
    /// Change this value to trigger animations on the table view.
    public var rows : [T] {
        didSet {
            
            let oldRows = oldValue
            let newRows = self.rows
            let changes = oldRows.diff(newRows)
            if (changes.count > 0) {
                tableView?.beginUpdates()
                
                let insertionIndexPaths = changes.filter({ $0.isInsertion }).map({ NSIndexPath(forRow: $0.idx, inSection: self.sectionIndex) })
                let deletionIndexPaths = changes.filter({ !$0.isInsertion }).map({ NSIndexPath(forRow: $0.idx, inSection: self.sectionIndex) })
                
                tableView?.insertRowsAtIndexPaths(insertionIndexPaths, withRowAnimation: insertionAnimation)
                tableView?.deleteRowsAtIndexPaths(deletionIndexPaths, withRowAnimation: deletionAnimation)
                
                tableView?.endUpdates()
            }
            
        }
    }
    
}
