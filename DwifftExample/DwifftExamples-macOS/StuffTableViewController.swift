import Cocoa
import Dwifft

final class StuffTableViewController: NSViewController {

  @IBOutlet weak var tableView: NSTableView!

  let itemIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("itemCell")
  var diffCalculator: TableViewDiffCalculator<String>?
  var stuff: [String] = Stuff.onlyWordItems() {
    // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
    didSet {
      self.diffCalculator?.rows = stuff
    }
  }

  @IBAction func shuffle(_ sender: NSButton) {
    self.stuff = Stuff.onlyWordItems()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    diffCalculator = TableViewDiffCalculator(tableView: tableView, initialRows: stuff, sectionIndex: 1)
    tableView.delegate = self
    tableView.dataSource = self
  }
}

extension StuffTableViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return diffCalculator?.rows.count ?? 0
  }
}

extension StuffTableViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard
      let item = tableView.makeView(withIdentifier: itemIdentifier, owner: nil) as? NSTableCellView,
      let word = diffCalculator?.rows[row]
    else {
      return nil
    }
    item.textField?.stringValue = word
    return item
  }
}
