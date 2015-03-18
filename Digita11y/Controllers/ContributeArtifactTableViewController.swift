import UIKit

class ContributeArtifactTableViewController: UITableViewController {
  
  var cells = ["Lovell Pressure Suit", "Telescope M-53", "Apollo XVII Moon Rock", "Apollo XIII Manual"]

  // MARK: - Table view data source

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.cells.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ContributeArtifactCellIdentifier", forIndexPath: indexPath) as! UITableViewCell
    cell.textLabel?.text = self.cells[indexPath.row]
    return cell
  }
}
