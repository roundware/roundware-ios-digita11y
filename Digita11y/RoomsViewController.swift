//
//  RoomsViewController.swift
//  Digita11y
//
//  Created by Christopher Reed on 2/29/16.
//  Copyright © 2016 Roundware. All rights reserved.
//

import UIKit
import RWFramework
import Crashlytics
import SwiftyJSON
import CoreLocation
import SVProgressHUD
import AVFoundation

class RoomsViewController: BaseViewController, RWFrameworkProtocol, AKPickerViewDataSource, AKPickerViewDelegate {
    var viewModel: RoomsViewModel!
    var objectViews : [ObjectView] = []
    var waitingToStart: Bool = false

    // MARK: Outlets

    @IBOutlet weak var roomsLabel: UILabel!
    @IBOutlet weak var roomsPickerView: AKPickerView!

    @IBOutlet weak var itemsLabel: UILabel!
    @IBOutlet weak var itemsScrollView: UIScrollView!

    //transport
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var toggleButton: PlayPauseButton!
    @IBOutlet weak var contributeButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var replayButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!

    @IBOutlet weak var moreButton: UIButton!

    // MARK: Player related actions
    @IBAction func toggleStream(_ sender: AnyObject) {
        let rwf = RWFramework.sharedInstance
        //TODO check
        if (self.skipButton.isEnabled) {
            DebugLog("pausing")
            SVProgressHUD.dismiss()
            countdownTimer.invalidate()
            rwf.stop()
            pauseLock = true

            self.toggleButton.showButtonIsPlaying(false)
            self.skipButton.isEnabled = false
            self.replayButton.isEnabled = false
            UIApplication.shared.isIdleTimerDisabled = false
        } else {
            //TODO check if item is selected?
            startPlaying()
        }
    }

    @IBAction func skip(_ sender: AnyObject) {

        DebugLog("skip item")
        let rwf = RWFramework.sharedInstance
        rwf.skip()
        let status = "Remixing your live audio stream… please hold!"
        SVProgressHUD.show(withStatus: status)
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status);
        }

        //mark current asset completed
        guard let currentAsset = self.viewModel.currentAsset,
            let objectViewIndex = objectViews.index(where: { $0.arrayOfAssetIds.contains( String(currentAsset.assetID) )}) else {
            DebugLog("no item to mark completed")
            return
        }
        objectViews[objectViewIndex].audioAssets[objectViews[objectViewIndex].audioAssets.index(where:{$0.assetID == currentAsset.assetID})!].completed = true

        //reset timer
        countdownTimer.invalidate()

        //don't reset currentAsset...let metadata do that
        waitingToStart = true

    }

    @IBAction func replay(_ sender: AnyObject) {
        DebugLog("replay")
        let rwf = RWFramework.sharedInstance
        rwf.replayAsset()
        let status = "Remixing your live audio stream… please hold!"
        SVProgressHUD.show(withStatus: status)
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status);
        }
    }


    // MARK: navigation

    @IBAction func contribute(_ sender: AnyObject) {
        stop()
        self.performSegue(withIdentifier: "ContributeSegue", sender: sender)
    }

    @IBAction func expandMore(_ sender: AnyObject) {
        guard let currentAsset = self.viewModel.currentAsset else {
            DebugLog("currentAsset not set")
            return
        }

        let assetID = String(currentAsset.assetID)
        let rwf = RWFramework.sharedInstance

        let moreModal = UIAlertController(title: "More actions", message: "", preferredStyle: UIAlertControllerStyle.alert)

        //Block Recording
        moreModal.addAction(UIAlertAction(title: "Block Asset", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
            rwf.apiPostAssetsIdVotes(asset_id: assetID, vote_type: "block_asset",
                success: { (data) -> Void in
                }, failure:  { (error) -> Void in
            })
        }))

        //Block User
        moreModal.addAction(UIAlertAction(title: "Block User", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                rwf.apiPostAssetsIdVotes(asset_id: assetID, vote_type: "block_user",
                    success: { (data) -> Void in
                    }, failure:  { (error) -> Void in
                })
        }))

        //Flag Recording
        moreModal.addAction(UIAlertAction(title: "Flag Recording", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
            rwf.apiPostAssetsIdVotes(asset_id: assetID, vote_type: "flag",
                success: { (data) -> Void in
                }, failure:  { (error) -> Void in
            })
        }))

        //Cancel
        moreModal.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(moreModal, animated: true, completion: nil)
    }

    var audioKeepsPlaying = false
    @IBAction func seeMap(_ sender: AnyObject) {
        audioKeepsPlaying = true
        self.performSegue(withIdentifier: "MapSegue", sender: sender)
    }


    // MARK: UIItem/Tag Actions
    @IBAction func selectObject(_ sender: UIButton) {
        DebugLog("selected item tag with button tag / objectView index \(String(sender.tag))")
        //find tag view

//        let objectView = objectViews[sender.tag]
//        if (objectView.selected){
//            DebugLog("this item was already selected")
//        } else {
            //TODO lock this to prevent UI jitter from metadata while stream buffers
            selectObjectViewAtIndex(sender.tag) //sets selectedObjectTag
            guard let thisTag = self.viewModel.selectedObjectTag else{
                DebugLog("selectedObjectTag not set")
                return
            }
            let thisTagId = thisTag.id
            DebugLog("thisTagId \(thisTagId)")
            let rwf = RWFramework.sharedInstance
            rwf.submitTags(tagIdsAsString: "\(thisTagId)")
            rwf.skip()
//        }
    }

   func selectObjectViewAtIndex(_ index: Int?) {
        self.viewModel.selectedObjectIndex = index

        guard let thisIndex = index else {
            objectViews.forEach({$0.selected = false })
            self.contributeButton.isEnabled = false
            return
        }

        self.contributeButton.isEnabled = true

        //set selected
        let objectView = objectViews[thisIndex]
        objectView.selected = true

        //deselect others
        let others = objectViews.filter({$0 !== objectView})
        others.forEach({$0.selected = false })

        //start playing if not playing
        let rwf = RWFramework.sharedInstance
        if(!rwf.isPlaying || pauseLock){
            startPlaying()
        }

        //set times
        countdownTime = Int(objectView.totalLength)
    }

    @IBAction func seeGalleryForAsset(_ sender: UIButton) {
        audioKeepsPlaying = true
        self.performSegue(withIdentifier: "GallerySegue", sender: sender)
        
    }

    @IBAction func seeTextForAsset(_ sender: UIButton) {
        audioKeepsPlaying = true
        self.performSegue(withIdentifier: "ReadSegue", sender: sender)
    }


    // MARK: Segue Actions

    //back from modals
    @IBAction func prepareForTagsDimiss(_ segue: UIStoryboardSegue) {
        //TODO move focus to current asset
    }
    //back from contribute
    @IBAction func prepareForTagsUnwind(_ segue: UIStoryboardSegue) {
        //TODO move focus to current asset
    }


    // MARK: Views

    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.dismiss()
        countdownTimer.invalidate()
        self.toggleButton.showButtonIsPlaying(false)
        self.contributeButton.isEnabled = false
        self.moreButton.isEnabled = false


        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        super.view.addBackground("bg-comment.png")
        self.viewModel = RoomsViewModel(data: self.rwData!)

        self.navigationItem.title = self.viewModel.title

        //set room pickerview
        self.roomsPickerView.delegate = self
        self.roomsPickerView.dataSource = self
        self.roomsPickerView.pickerViewStyle = .flat
        self.roomsPickerView.viewDepth = 0
        self.roomsPickerView.maskDisabled = true
        self.roomsPickerView.font = UIFont(name: "AvenirNext-Medium", size: 30)!
        self.roomsPickerView.highlightedFont = UIFont(name: "AvenirNext-Medium", size: 30)!
        self.roomsPickerView.reloadData()
        self.roomsPickerView.selectItem(0)

        self.roomsLabel.accessibilityTraits |= UIAccessibilityTraitHeader
        self.itemsLabel.accessibilityTraits |= UIAccessibilityTraitHeader
        self.playerLabel.accessibilityTraits |= UIAccessibilityTraitHeader

        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(object: self)

        //TODO double check for location...
        // TODO move this location stuff out of here

        // if it's not enabled, bounce the user back to the location screen?

        // location services should be asked for here if they are:
        // a. "required" based server sent config hash
        // b. not already authorized
        //        if (CLLocationManager.authorizationStatus() != .authorizedWhenInUse){
        //
        //            let alertController = UIAlertController (title: "Location services", message: "Please enable location detection for streaming", preferredStyle: .alert)
        //
        //            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
        //                let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        //                if let url = settingsUrl {
        //                    UIApplication.shared.openURL(url)
        //                }
        //            }
        //
        //            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        //            alertController.addAction(settingsAction)
        //            alertController.addAction(cancelAction)
        //            present(alertController, animated: true, completion: nil)
        //            return false
        //
        //        } else {

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (audioKeepsPlaying){
            audioKeepsPlaying = false
        } else {
            stop()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(false, animated: true)

        //show a map button if we have a map
        if !self.rwData!.selectedProject!.mapURL.isEmpty {
            let button: UIButton = UIButton(type:UIButtonType.custom)
            //set image for button
            button.setImage(UIImage(named: "map.png"), for: UIControlState())
            //add function for button
            button.addTarget(self, action: #selector(self.seeMap(_:)), for: UIControlEvents.touchUpInside)
            //set frame
            button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            button.accessibilityHint = "Tap to view map"
            let mapButton = UIBarButtonItem(customView: button)
            //assign button to navigationbar
            self.navigationItem.rightBarButtonItem = mapButton
        }

    }

    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        let scroll = itemsScrollView
        let newContentOffsetX = ((scroll?.contentSize.width)!/2) - ((scroll?.bounds.size.width)!/2)
        scroll?.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: Player logic

    //countdown timer init
    var countdownTime = 0
    var countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(RoomsViewController.countdown), userInfo: nil, repeats: true)

    func countdown() {
//        DebugLog("counting down \(countdownTime)")
         if countdownTime >= 0 {
            let seconds = countdownTime % 60
            let minutes = (countdownTime / 60) % 60
            //            debugPrint("seconds \(seconds)")
            //            debugPrint("minutes \(minutes)")
            let countdownText = String(format: "%02d:%02d", minutes, seconds)
            countdownLabel.text = countdownText
            countdownLabel.accessibilityLabel = "\(minutes) minutes and \(seconds) seconds total for this tag"
            countdownTime -= 1

            //update progress on current objectView
            guard let index = self.viewModel.selectedObjectIndex,
                objectViews.indices.contains(index) else{
                    DebugLog("no selected item index")
                return
            }
            let objectView = objectViews[index]
//            DebugLog("countdownTime \(countdownTime) objectView.TotalLength \(objectView.totalLength)")

            let percentage = Float((objectView.totalLength - Float(countdownTime)) / (objectView.totalLength))
//            DebugLog("progress \(percentage)")
            objectView.objectProgress.setProgress(percentage, animated: true)
         } else{
            countdownTimer.invalidate()
            selectObjectViewAtIndex(nil)
        }
    }

    func stop() {
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        self.toggleButton.showButtonIsPlaying(false)
        self.skipButton.isEnabled = false
        self.replayButton.isEnabled = false
        countdownTimer.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
        SVProgressHUD.dismiss()
    }

    var pauseLock = false
    func startPlaying() {
        let rwf = RWFramework.sharedInstance
        if(pauseLock){
            rwf.resume()
            let status = "Buffering Stream"
            SVProgressHUD.show(withStatus: status)
        } else {
            rwf.play()
            let status = "Loading Stream"
            SVProgressHUD.show(withStatus: status)
            if (UIAccessibilityIsVoiceOverRunning()) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status);
            }
        }
        waitingToStart = true

        self.toggleButton.showButtonIsPlaying(true)
        self.skipButton.isEnabled = true
        self.replayButton.isEnabled = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    // MARK: - AKPickerViewDataSource
    func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int {
        return self.viewModel.roomTags.count
    }

    func pickerView(_ pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.viewModel.roomTags[item].locMsg
    }

    func pickerView(_ pickerView: AKPickerView, accessibilityLabelForItem item: Int) -> String {
        let label = self.viewModel.roomTags[item].locMsg + ", \(item + 1) of \(self.viewModel.roomTags.count)"
        DebugLog(label)
        return label
    }

    func pickerView(_ pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
        label.textColor = UIColor.lightGray
        label.highlightedTextColor = UIColor.black
        label.backgroundColor = UIColor.white
    }

    func pickerView(_ pickerView: AKPickerView, marginForItem item: Int) -> CGSize {
        return CGSize(width: 20, height: 20)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // println("\(scrollView.contentOffset.x)")
    }


    // MARK: - AKPickerViewDelegate
    // item = pickerView item -> room UIItem
    func pickerView(_ pickerView: AKPickerView, didSelectItem item: Int) {
        DebugLog("selected room with index \(item)")
        if( self.viewModel.selectedRoomIndex != item){
            self.viewModel.selectedRoomIndex = item
            let duration = 0.5
            let delay = 0.1
            let springDamping = CGFloat(0.5)
            let springVelocity = CGFloat(0.5)
            let scroll = itemsScrollView

            //hide old assets
            for (index, item) in (scroll?.subviews.enumerated())!{
                UIView.animate(withDuration: duration, delay: Double(index) * delay, usingSpringWithDamping: springDamping, initialSpringVelocity: springVelocity, options: [], animations: {
                    item.alpha = 0
                    item.center.y -= 30
                }, completion: { finished in
                    item.removeFromSuperview()
                })
            }

            //show new assets
            let total = self.viewModel.objectTags.count
            DebugLog("\(total) items in this room")
            //        dump(self.viewModel.itemTags)
            scroll?.delegate = self
            let itemWidth = 300
            let itemHeight = 80
            scroll?.contentSize.width = CGFloat(itemWidth)
            scroll?.contentSize.height = CGFloat(itemHeight * total)

            objectViews = []

            for index in 0..<total {
                let objectView = ObjectView()
                let tag = self.viewModel.objectTags[index]
                let images = self.viewModel.data.getAssetsForTagIdOfMediaType(tag.id, mediaType: MediaType.photo)
                let texts = self.viewModel.data.getAssetsForTagIdOfMediaType(tag.id, mediaType: MediaType.text)

                objectView.hasImages = images.count > 0
                //            debugPrint("objectView index \(index) has \(images.count) images")
                objectView.hasTexts = texts.count > 0
                objectView.setObject(tag, index: index, total: total)

                //TODO should really go into setObject and use delegate...
                objectView.objectTitle.addTarget(self,
                                           action: #selector(selectObject),
                                           for: UIControlEvents.touchUpInside)
                //TODO needs unique tag?
                objectView.objectTitle.tag = index

                //show text button?
                if(objectView.hasTexts){
                    objectView.textButton.addTarget(self,
                                                 action: #selector(seeTextForAsset(_:)),
                                                 for: UIControlEvents.touchUpInside)
                    //TODO needs unique tag?
                    objectView.textButton.tag = tag.id
                }

                //show gallery button?
                if(objectView.hasImages){
                    objectView.cameraButton.addTarget(self,
                                                   action: #selector(seeGalleryForAsset(_:)),
                                                   for: UIControlEvents.touchUpInside)
                    //TODO needs unique tag?
                    objectView.cameraButton.tag = tag.id
                }

                //determine audio assets and total length
                let audioAssets = self.viewModel.data.getAssetsForTagIdOfMediaType(objectView.id!, mediaType: MediaType.audio)
                objectView.audioAssets = audioAssets
                let totalLength = audioAssets.map({$0.audioLength}).reduce(0, +)
                objectView.totalLength = totalLength
                let arrayOfAssetIds = audioAssets.map({ String($0.assetID)})
                objectView.arrayOfAssetIds = arrayOfAssetIds
                //            debugPrint("audio assets for tag \(objectView.id!)")
                //            dump(audioAssets)
                //            debugPrint("total length is \(totalLength)")

                let frame = CGRect(
                    x: 0,
                    y: index * itemHeight,
                    width: Int(itemWidth),
                    height: itemHeight)
                objectView.frame = frame
                objectView.alpha = 0
                objectView.center.y -= 30
                scroll?.addSubview(objectView)
                UIView.animate(withDuration: duration, delay: Double(index) * delay, usingSpringWithDamping: springDamping, initialSpringVelocity: springVelocity, options: [], animations: {
                    objectView.alpha = 1
                    objectView.center.y += 30
                }, completion: { finished in
                })
                objectViews.append(objectView)
            }

            //select first item tag
//            if(objectViews.count > 0){
//                selectObjectViewAtIndex(0)
//            }

        }
    }

    // MARK: RWFramework Protocol

//    func rwGetStreamsIdCurrentSuccess( data: NSData?) {
//        DebugLog("current success")
//    }

//    func rwPostStreamsSuccess( data: NSData?) {
//        DebugLog("stream success")
//    }

    func rwPostStreamsError( error: NSError?) {
        DebugLog((error?.localizedDescription)!)
    }

//    func rwPatchStreamsIdSuccess( data: NSData?){
//        DebugLog("patch stream success")
//    }

    func rwPatchStreamsIdFailure( error: NSError?){
        DebugLog((error?.localizedDescription)!)
    }

//    func rwPostStreamsIdHeartbeatSuccess( data: NSData?) {
//    }

    func rwPostStreamsIdHeartbeatFailure( error: NSError?){
        DebugLog((error?.localizedDescription)!)
    }

    func rwPostStreamsIdSkipSuccess( data: NSData?) {
        DebugLog("skip success")
//        dump(data)
    }

    func rwPostStreamsIdSkipFailure( error: NSError?) {
        DebugLog((error?.localizedDescription)!)
        let alert = UIAlertController(title: "Error", message: "rwPostStreamsIdSkipFailure", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func rwPostStreamsIdResumeSuccess( data: NSData?) {
        DebugLog("resume success")
    }

    func rwPostStreamsIdResumeFailure( error: NSError?) {
        DebugLog((error?.localizedDescription)!)
        let alert = UIAlertController(title: "Error", message: "rwPostStreamsIdResumeFailure", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

//    func rwPostStreamsIdReplayAssetSuccess( data: NSData?) {
//        DebugLog("replay success")
//    }

    func rwPostStreamsIdReplayAssetFailure(error: NSError?){
        DebugLog((error?.localizedDescription)!)
        let alert = UIAlertController(title: "Error", message: "rwPostStreamsIdReplayAssetFailure", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func rwGetAssetsIdSuccess( data: NSData?){
        DebugLog("get asset id success")
//        dump(data)
    }

    func rwGetAssetsIdFailure( error: NSError?){
        DebugLog((error?.localizedDescription)!)
    }

    func rwAudioPlayerDidFinishPlaying() {
        DebugLog("audio player did finish")
        stop()
    }

    func rwObserveValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutableRawPointer?) {

        //        debugPrint("keypath")
        //        dump(keyPath)
        //        print("object")
        //        dump(object)

        //        debugPrint("change")
        //        dump(change)
        //        debugPrint("context")
        //        dump(context)
        
        //the stream has started
        if keyPath == "timedMetadata" {

            //TODO what metadata should we actually be waiting for
            //TODO dismiss modal after resume
            if waitingToStart{
                DebugLog("playback has begun in stream")
                waitingToStart = false
                SVProgressHUD.dismiss()
                self.toggleButton.showButtonIsPlaying(true)
            }

            //get values
            guard let newChange = change?[.newKey] as? NSArray,
                let avMetadataItem = newChange.firstObject as? AVMetadataItem else{
                DebugLog("no change or metadatadataitem")
                return
            }

            guard var value = avMetadataItem.value as? String else{
                DebugLog("value problem")
                return
            }
            value = value.replacingOccurrences(of: "Roundware - ", with: "?", options: NSString.CompareOptions.literal, range: nil)
            guard let params = URL(string: value) else{
                DebugLog("param problem")
                DebugLog(value)
                return
            }
            guard let queryItems = params.queryItems else{
                DebugLog("query problem")
                DebugLog(String(describing: params))
                return
            }

            //ok we have our values
            //let see what asset we are on
            guard let assetID = queryItems["asset"],
            let thisAsset = self.viewModel.data.getAssetById(Int(assetID)!)
                else{
                DebugLog("missing assetID \(String(describing: queryItems["asset"]))")
                return
            }

            guard let objectViewIndex = objectViews.index(where: { $0.arrayOfAssetIds.contains( assetID )}) else {
                DebugLog("no matching objectView found for \(assetID)")
                return
            }

            guard let index = self.viewModel.selectedObjectIndex else {
                DebugLog("no item was previously selected")
                selectObjectViewAtIndex(objectViewIndex)
                return
            }

            if(self.viewModel.currentAsset != nil && thisAsset.assetID == self.viewModel.currentAsset!.assetID ){
                DebugLog("same asset")
                if queryItems["complete"] != nil  {
                    objectViews[objectViewIndex].audioAssets[objectViews[objectViewIndex].audioAssets.index(where:{$0.assetID == thisAsset.assetID})!].completed = true
                    moreButton.isEnabled = false
                }
                if (objectViews[objectViewIndex].audioAssets.filter({$0.completed == false}).count == 0){
                    objectViews[objectViewIndex].completed = true
                }

            } else {
                DebugLog("new asset")
                moreButton.isEnabled = true

                self.viewModel.currentAsset = thisAsset
                SVProgressHUD.dismiss()

                let remainingTime = objectViews[objectViewIndex].audioAssets.filter({$0.completed == false}).map({$0.audioLength}).reduce(0, +)
                DebugLog("remainingTime \(remainingTime)")
                if(countdownTimer.isValid){
                    countdownTimer.invalidate()
                }
                countdownTime = Int(remainingTime)
                countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(RoomsViewController.countdown), userInfo: nil, repeats: true)

                if(objectViewIndex == index) {
                    DebugLog("stream metadata confirms current tag view")
                } else {
                    DebugLog("new tag view selected, update ui")
                    selectObjectViewAtIndex(objectViewIndex)
                }
            }
        }
    }
}
