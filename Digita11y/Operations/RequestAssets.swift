import Foundation
import Crashlytics
import RWFramework

func requestAssets(completion: (assets: [Asset]) -> ()) {
  if let projectData = RWFrameworkConfig.getConfigDataFromGroup(group: RWFrameworkConfig.ConfigGroup.Project) as? NSDictionary {
    var rwf = RWFramework.sharedInstance
    let project_id = projectData["project_id"] as! NSNumber
    let dict: [String:String] = ["project_id": project_id.stringValue]
    rwf.apiGetAssets(dict, success: { (data) -> Void in
      if (data != nil) {
        let json = JSON(data: data!)
        let assets = json.array?.map { Asset(json: $0) } ?? []
        completion(assets: assets.filter { $0.submitted })
      }
      }) { (error) -> Void in
        debugPrintln(error.localizedDescription)
        CLSNSLogv(error.localizedDescription, getVaList([]))
        completion(assets: [])
    }
  }
}