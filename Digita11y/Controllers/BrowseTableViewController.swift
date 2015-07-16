import UIKit
import RWFramework

class BrowseTableViewController: BaseTableViewController, RWFrameworkProtocol {

  var exhibitionViewModel: ExhibitionViewModel?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 125.0
    tableView.tableFooterView = UIView(frame: CGRectZero)

    RWFramework.sharedInstance.addDelegate(self)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)

    exhibitionViewModel = ExhibitionViewModel(data: self.rwData!)
  }

  // MARK: - Table view data source

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.exhibitionViewModel?.numberOfExhibitions() ?? 0
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    if let cell = tableView.dequeueReusableCellWithIdentifier(BrowseTableViewCell.Identifier, forIndexPath: indexPath) as? BrowseTableViewCell {
      cell.tag = self.exhibitionViewModel?.IDForIndex(indexPath.row) ?? 0
      cell.titleLabel.text = self.exhibitionViewModel?.titleForIndex(indexPath.row) ?? ""
      cell.accessibilityLabel = self.exhibitionViewModel?.accessibilityLabelForIndex(indexPath.row) ?? ""
      cell.accessibilityTraits = UIAccessibilityTraitButton;
      cell.bannerImageView.sd_setImageWithURL(self.exhibitionViewModel?.imageURLForIndex(indexPath.row), placeholderImage: UIImage(named:"browse-cell"))

      return cell
    }

    return UITableViewCell()
  }


  // MARK: - Navigation

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    super.prepareForSegue(segue, sender: sender)

    if segue.identifier == "BrowseDetailSegue" {
      if let to = segue.destinationViewController as? BrowseDetailTableViewController,
           cell = sender as? UITableViewCell {
        to.exhibitionID = cell.tag

        var rwf = RWFramework.sharedInstance
        rwf.setListenTagsCurrent("exhibition", value: [to.exhibitionID])
        rwf.submitListenTags()

        rwf.setSpeakTagsCurrent("exhibition", value: [to.exhibitionID])
      }
    }
  }

  // MARK: - RWFrameworkProtocol

  func rwUpdateStatus(message: String) {}

  func rwGetProjectsIdTagsSuccess(data: NSData?) {
    // Order or operations thing.  RootTabBarController parses exhibitions
    delay(0.1) {
      self.tableView.reloadData()
    }
  }
}
