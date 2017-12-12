import Cocoa
import Dwifft

final class StuffCollectionViewController: NSViewController {

  @IBOutlet weak var collectionView: NSCollectionView!

  let itemIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("emojiItem")
  let headerIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("sectionHeader")
  var diffCalculator: CollectionViewDiffCalculator<String, String>?
  var stuff: SectionedValues<String, String> = Stuff.emojiStuff() {
    // So, whenever your datasource's array of things changes, just let the diffCalculator know and it'll do the rest.
    didSet {
      self.diffCalculator?.sectionedValues = stuff
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    diffCalculator = CollectionViewDiffCalculator(collectionView: collectionView, initialSectionedValues: stuff)

    let itemNib = NSNib(nibNamed: NSNib.Name(rawValue: "StuffCollectionViewItem"), bundle: nil)
    collectionView.register(itemNib, forItemWithIdentifier: itemIdentifier)

    let headerNib = NSNib(nibNamed: NSNib.Name(rawValue: "StuffCollectionHeaderView"), bundle: nil)
    collectionView.register(headerNib, forSupplementaryViewOfKind: .sectionHeader, withIdentifier: headerIdentifier)
  }

  @IBAction func shuffle(_ sender: NSButton) {
    self.stuff = Stuff.emojiStuff()
  }
}

extension StuffCollectionViewController: NSCollectionViewDataSource {
  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    return diffCalculator?.numberOfSections() ?? 0
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return diffCalculator?.numberOfObjects(inSection: section) ?? 0
  }

  func collectionView(_ collectionView: NSCollectionView,
                      viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
                      at indexPath: IndexPath) -> NSView {
    let header = collectionView.makeSupplementaryView(ofKind: .sectionHeader, withIdentifier: headerIdentifier, for: indexPath)

    if let dc = diffCalculator, let stuffHeader = header as? StuffCollectionHeaderView {
      stuffHeader.title.stringValue = dc.value(forSection: indexPath.section)
    }

    return header
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: itemIdentifier, for: indexPath)

    if let dc = diffCalculator, let emojiItem = item as? StuffCollectionViewItem {
      emojiItem.textField?.stringValue = dc.value(atIndexPath: indexPath)
    }

    return item
  }
}

final class StuffCollectionHeaderView: NSView {
  @IBOutlet weak var title: NSTextField!
}
