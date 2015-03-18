import UIKit
import RWFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RWFrameworkProtocol {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)

    setupRWFramework()

    return true
  }

  func setupRWFramework() {
    var rwf = RWFramework.sharedInstance
    rwf.delegate = self
    rwf.start()
  }

  func rwUpdateStatus(message: String) {
    //debugPrintln(message)
  }

  func rwPostUsersFailure(error: NSError?) {
    debugPrintln(error)
  }

  func rwPostSessionsSuccess() {
  }
}
