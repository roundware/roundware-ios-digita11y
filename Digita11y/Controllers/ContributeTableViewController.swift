import UIKit
import RWFramework

class ContributeTableViewController: UITableViewController, RWFrameworkProtocol {

  enum Cell {
    case Artifact
    case Audio
    case AudioDrawer
    case Photo
    case PhotoDrawer
    case Text
    case TextDrawer
  }

  var cells = [Cell.Artifact, Cell.Audio, Cell.Photo, Cell.Text]

  let CellIdentifier = "ContributeCellIdentifier"
  let AudioDrawerCellIdentifier = "AudioDrawerCellIdentifier"
  let PhotoDrawerCellIdentifier = "PhotoDrawerCellIdentifier"
  let TextDrawerCellIdentifier = "TextDrawerCellIdentifier"

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 125.0
  }

  // MARK: - Table view data source

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
      return 1
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cells.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let type = self.cells[indexPath.row]
    switch (type) {
    case .Artifact:
      return tableView.dequeueReusableCellWithIdentifier("ArtifactCellIdentifier", forIndexPath: indexPath) as! UITableViewCell
    case .Audio:
      var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
      cell.textLabel?.text = "Audio"
      cell.accessoryView = UIImageView(image: UIImage(named: "microphone"))
      cell.selectionStyle = .None
      return cell
    case .AudioDrawer:
      var cell =  tableView.dequeueReusableCellWithIdentifier(AudioDrawerCellIdentifier, forIndexPath: indexPath) as! AudioDrawerTableViewCell
      cell.recordButton.tag = indexPath.row
      cell.recordButton.addTarget(self, action: "recordAudio:", forControlEvents: .TouchUpInside)
      cell.uploadButton.addTarget(self, action: "uploadAudio", forControlEvents: .TouchUpInside)
      return cell
    case .Photo:
      var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
      cell.textLabel?.text = "Photos"
      cell.accessoryView = UIImageView(image: UIImage(named: "image"))
      cell.selectionStyle = .None
      return cell
    case .PhotoDrawer:
      var cell = tableView.dequeueReusableCellWithIdentifier(PhotoDrawerCellIdentifier, forIndexPath: indexPath) as! PhotoDrawerTableViewCell
      cell.textView.placeholder = "Describe this photo..."
      cell.textView.placeholderTextColor = UIColor.lightGrayColor()
      cell.cameraButton.addTarget(self, action: "cameraButton", forControlEvents: .TouchUpInside)
      cell.libraryButton.addTarget(self, action: "libraryButton", forControlEvents: .TouchUpInside)
      return cell
    case .Text:
      var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: CellIdentifier)
      cell.textLabel?.text = "Text"
      cell.accessoryView = UIImageView(image: UIImage(named: "text"))
      cell.selectionStyle = .None
      return cell
    case .TextDrawer:
      var cell = tableView.dequeueReusableCellWithIdentifier(TextDrawerCellIdentifier, forIndexPath: indexPath) as! TextDrawerTableViewCell
      cell.textView.placeholder = "Write something..."
      cell.textView.placeholderTextColor = UIColor.lightGrayColor()
      return cell
    }
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let type = self.cells[indexPath.row]

    switch (type) {
    case .Audio:
      toggleDrawer(Cell.AudioDrawer, parent: Cell.Audio)
    case .Photo:
      toggleDrawer(Cell.PhotoDrawer, parent: Cell.Photo)
    case .Text:
      toggleDrawer(Cell.TextDrawer, parent: Cell.Text)
    default:
      break
    }
  }

  func toggleDrawer(drawer: Cell, parent: Cell) {
    // Remove drawer?
    for (var i = 0; i < self.cells.count; ++i) {
      if self.cells[i] == drawer {
        self.cells.removeAtIndex(i)
        self.tableView.beginUpdates()
        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
        self.tableView.endUpdates()
        return
      }
    }
    // Must be that we have to add the drawer
    for (var i = 0; i < self.cells.count; ++i) {
      if self.cells[i] == parent {
        self.cells.insert(drawer, atIndex: i+1)
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: i+1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
        self.tableView.endUpdates()
        return
      }
    }
  }

  func recordAudio(button: UIButton) {
    var rwf = RWFramework.sharedInstance
    rwf.delegate = self
    if rwf.isRecording() {
      rwf.stopRecording()
    } else {
      setupAudio() { granted, error in
        debugPrintln("Audio granted: \(granted), Error: \(error)")
        if granted && error == nil {
          debugPrintln("Start recording")
          rwf.startRecording()
        }
      }
    }

    var indexPath = NSIndexPath(forRow: button.tag, inSection: 0)
    if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AudioDrawerTableViewCell {
      cell.uploadButton.enabled = true
      cell.uploadButton.setNeedsDisplay()
    }
  }

  func uploadAudio() {
    debugPrintln("uploadAudio")
    var rwf = RWFramework.sharedInstance
    rwf.delegate = self
    rwf.addRecording()
  }

  func cameraButton() {
    var rwf = RWFramework.sharedInstance
    rwf.delegate = self
    rwf.doImage()
  }

  func libraryButton() {
    var rwf = RWFramework.sharedInstance
    rwf.delegate = self
    rwf.doPhotoLibrary()
  }

  func rwRecordingProgress(percentage: Double) {
    for var i = 0; i < self.tableView.numberOfRowsInSection(0); ++i {
      var indexPath = NSIndexPath(forRow: i, inSection: 0)
      if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? AudioDrawerTableViewCell {
        cell.progressLabel.text = String(format:"%f", percentage)
        return
      }
    }
  }

  func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject]) {
    for var i = 0; i < self.tableView.numberOfRowsInSection(0); ++i {
      var indexPath = NSIndexPath(forRow: i, inSection: 0)
      if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PhotoDrawerTableViewCell {
        cell.textView.hidden = false
        cell.photoView.hidden = false

        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
          cell.photoView.image = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
          cell.photoView.image = image
        }
        return
      }
    }
  }
}
