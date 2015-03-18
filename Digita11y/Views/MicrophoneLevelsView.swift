import UIKit
import CoreGraphics

class MicrophoneLevelsView: UIView {

  @IBInspectable var onColor: UIColor = UIColor.blueColor()
  @IBInspectable var offColor: UIColor = UIColor.redColor()
  @IBInspectable var numLevels: Int = 20
  @IBInspectable var percent: Float = 0.3

  var timer: NSTimer?
  var angle: Float = 0.0

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    self.timer?.fire()
  }

  func update() {
    angle += 0.1
    self.percent = abs(sin(angle))
    self.setNeedsDisplay()
  }

  override func drawRect(rect: CGRect) {
    var ctx = UIGraphicsGetCurrentContext()

    onColor.set()
    for var i = 0; i < self.numLevels; ++i {
      if (i%2 == 0) {
        if (Float(i)/Float(self.numLevels) > self.percent) {
          self.offColor.set()
        } else {
          self.onColor.set()
        }
        var w = rect.width/CGFloat(self.numLevels)
        var x = CGFloat(i) * w + rect.origin.x
        var rc = CGRectMake(x, rect.origin.y, w, rect.height)
        UIRectFill(rc)
      }
    }
  }
}
