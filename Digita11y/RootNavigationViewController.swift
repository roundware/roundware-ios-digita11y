//
//  RootNavigationViewController.swift
//  Digita11y
//
//  Created by Christopher Reed on 3/12/16.
//  Copyright © 2016 Roundware. All rights reserved.
//

import Foundation
import UIKit
import RWFramework
import Crashlytics
import SwiftyJSON
import CoreLocation


class RootNavigationViewController: UINavigationController, UINavigationControllerDelegate, RWFrameworkProtocol {
    static var once: Int = 0

    var rwData: RWData?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "AvenirNext-Bold", size: 20)!, NSForegroundColorAttributeName: UIColor.white]
        self.navigationBar.isTranslucent = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let vc = self.topViewController as? BaseViewController{
            vc.rwData = self.rwData
        }
    }

    // MARK: - RWFrameworkProtocol

    func rwUpdateStatus( message: String) {
        DebugLog(message)
    }

    func rwPostUsersFailure( error: NSError?) {
        DebugLog("post users failure")
        DebugLog((error?.localizedDescription)!)
    }

    func rwPostSessionsFailure( error: NSError?){
        DebugLog("post sessions failure")
        DebugLog((error?.localizedDescription)!)
    }


    func rwGetProjectsIdTagsSuccess( data: NSData?) {
        let json = JSON(data: data! as Data)
        self.rwData?.tags = json["tags"].array?.map { Tag(json: $0) } ?? []
    }

    func rwGetProjectsIdTagsFailure( error: NSError?) {
        DebugLog("get projects id tags failure")
        DebugLog((error?.localizedDescription)!)
    }

    func rwGetProjectsIdUIGroupsSuccess( data: NSData?) {
        let json = JSON(data: data! as Data)
//        dump(json)
        self.rwData?.uiGroups = json["ui_groups"].array?.map { UIGroup(json: $0) } ?? []
        dump(self.rwData?.uiGroups)

    }

    func rwGetProjectsIdUIGroupsFailure( error: NSError?) {
        DebugLog("get projects id ui groups failure")
        DebugLog((error?.localizedDescription)!)
    }

    func rwGetAssetsSuccess( data: NSData?) {
        let json = JSON(data: data! as Data)
        self.rwData?.assets = json.array?.map { Asset(json: $0) } ?? []
//        debugPrint("assets json received")
//        dump(self.rwData?.assets)
    }

    func rwGetAssetsFailure( error: NSError?) {
        DebugLog("get assets failure")
        DebugLog((error?.localizedDescription)!)
    }
}
