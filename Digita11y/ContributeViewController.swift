//
//  ContributeViewController.swift
//  Digita11y
//
//  Created by Christopher Reed on 2/29/16.
//  Copyright © 2016 Roundware. All rights reserved.
//

import UIKit
import Foundation
import Crashlytics
import RWFramework
import SVProgressHUD
import AVFoundation

class ContributeViewController: BaseViewController, UIScrollViewDelegate, UITextViewDelegate, RWFrameworkProtocol{
    var viewModel: ContributeViewModel!

    // MARK: Outlets and Actions

    @IBOutlet weak var ContributeAsk: UILabelHeadline!
    @IBOutlet weak var ContributeScroll: UIScrollView!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!

    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!

    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var responseTextView: UITextView!


    //TODO rename as tappedAudioButton
    @IBAction func selectAudio(_ sender: AnyObject) {
        if(!self.viewModel.mediaSelected){
            let duration = 0.1
            UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
                self.textButton.isHidden = true
                self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc
                self.tagLabel.isHidden = false
                self.tagLabel.text = self.viewModel.itemTag.locMsg
                self.audioButton.isEnabled = false
            }, completion: { finished in
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.ContributeAsk);
            })

            showTags()

            viewModel.mediaType = MediaType.audio
            viewModel.mediaSelected = true
            //TODOnow move focus to question

        } else {
            if(self.viewModel.tagsSelected){
            //record, play, stop
                let rwf = RWFramework.sharedInstance
                if rwf.isRecording() {
//                    delay(0.5) {  // HACK: Let the buffers in the framework flush.
                        rwf.stopRecording()
                        rwAudioRecorderDidFinishRecording()
//                    }
                } else if rwf.isPlayingBack() {
                    rwf.stopPlayback()
                    displayPreviewAudio()
                } else if rwf.hasRecording() {
                    rwf.startPlayback()
                    displayStopPlayback()
                } else {
                    rwf.startRecording()
                    displayStopRecording()
                }
            }

        }

    }

    //TODO rename as tappedSelectButton
    @IBAction func selectText(_ sender: AnyObject) {
        if(!self.viewModel.mediaSelected){

            let duration = 0.1
            UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
                self.audioButton.isHidden = true
                self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc
                self.tagLabel.text = "Text"
                self.textButton.isEnabled = false
                }, completion: { finished in
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.ContributeAsk);

            })

            showTags()

            viewModel.mediaType = MediaType.text
            self.viewModel.mediaSelected = true
            //TODOnow move focus to question
        }
    }

    @IBAction func selectedThis(_ sender: AnyObject) {
        let scroll = ContributeScroll
        let selectedView = sender as! UIView

        //hide others
        let others = scroll?.subviews.filter({$0 as UIView != selectedView})
        for (_, button) in (others?.enumerated())!{
            button.isHidden = true
        }

        //move selected to top
        selectedView.frame =  CGRect(
            x: selectedView.frame.origin.x,
            y: 0,
            width: selectedView.frame.width,
            height: selectedView.frame.height
        )
        scroll?.contentSize.width = selectedView.frame.width
        scroll?.contentSize.height = selectedView.frame.height


        //set tag into viewmodel
        self.viewModel.selectedTag = self.viewModel.data.getTagById(sender.tag)
        if(!self.viewModel.tagsSelected){
            self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc
            showTags()
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.ContributeAsk);
        } else {
            //tags are selected!
            if let button = sender as? UIButton {
                button.isEnabled = false
            }
            showMedia()
        }
        DebugLog("tags selected: \(self.viewModel.tagIds())")


    }

    func showMedia() {
        if(viewModel.mediaType == MediaType.audio){
            setupAudio() { granted, error in
                if granted == false {
                    DebugLog("Unable to setup audio: \(String(describing: error))")
                    if let error = error {
                        DebugLog("Unable to setup audio: \(error)")
                    }
                    //TODOnow alert message
                } else {
                    self.displayRecordAudio()
                }
            }
        } else {
            //is text
            let duration = 0.1

            UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
                self.responseTextView.isHidden = false
                self.tagLabel.isHidden = true
                self.textButton.isHidden = true
                }, completion: { finished in
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.responseTextView);
            })
        }
    }

    @IBAction func cancel(_ sender: AnyObject) {
        let rwf = RWFramework.sharedInstance
        if(rwf.hasRecording()){
            rwf.deleteRecording()
        }
        self.performSegue(withIdentifier: "cancel", sender: nil)
    }

    @IBAction func undo(_ sender: AnyObject) {
        DebugLog("undoing")
        let rwf = RWFramework.sharedInstance

        if(self.viewModel.mediaType == MediaType.audio){
            rwf.deleteRecording()
        } else {
            self.responseTextView.text = "Your response here"
        }
        showMedia()
    }

    @IBAction func upload(_ sender: AnyObject) {
        let rwf = RWFramework.sharedInstance

        if (rwf.isPlayingBack()) {
            rwf.stopPlayback()
            displayPreviewAudio()
        }

        //images
//        for image in self.viewModel.images {
//            rwf.setImageDescription(image.path, description: image.text)
//        }
//        self.images.removeAll()
//        self.uploadText = ""
        if self.viewModel.mediaType == MediaType.text {
            let _ = rwf.addText(string: self.viewModel.uploadText)
            DebugLog("text added")
        } else {
            let _ = rwf.addRecording()
            DebugLog("recording added")
        }

        rwf.uploadAllMedia(tagIdsAsString: self.viewModel.tagIds())
        let status = "Uploading"
        SVProgressHUD.show(withStatus: status)
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status);
        }
    }


    // MARK: Segue Actions
    //back from thank you
    @IBAction func prepareForRecontribute(_ segue: UIStoryboardSegue) {
        self.navigationController!.setNavigationBarHidden(false, animated: true)
        DebugLog("prepare for recontribute")

        self.viewModel.data = self.rwData!
        self.viewModel.resetForRecontribute()

        //set header
        self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc

        //show selected tag
        self.viewModel.tags = [self.viewModel.data.getTagById(self.viewModel.uiGroup.selectedUIItem!.tagId)!]
        showTags(false)
        self.undo(self)
    }

    // MARK: View
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //keyboard with view adjustment as well as done button and outside tap dismissal

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.dismiss()
        UIApplication.shared.isIdleTimerDisabled = false
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(dismissKeyboard))
        let toolBar = UIToolbar()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        responseTextView.inputAccessoryView = toolBar

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        super.view.addBackground("bg-comment.png")
        self.viewModel = ContributeViewModel(data: self.rwData!)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel(_:)))
        ContributeAsk.text = "How would you like to contribute to \(self.viewModel.itemTag.locMsg)?"

        ContributeScroll.isHidden = true
        uploadButton.isHidden = true
        undoButton.isHidden = true
        tagLabel.isHidden = true
        progressLabel.isHidden = true
        responseLabel.isHidden = true
        responseTextView.isHidden = true
        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(object: self)
        ContributeScroll.delegate = self
        responseTextView.delegate = self

        //http://stackoverflow.com/questions/26070242/move-view-with-keyboard-using-swift
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Tags layout
    func showTags(_ enabled: Bool = true){
        let scroll = ContributeScroll
        scroll?.isHidden = false
        scroll?.delegate = self

        let tags = self.viewModel.tags
        let total = tags.count

        let buttons = createTagButtonsForScroll(total, scroll: scroll!)
        //set titles and actions
        for (index, button) in buttons.enumerated(){
            let tag = tags[index]
            button.setTitle(tag.locMsg, for: UIControlState())
            button.accessibilityLabel = tag.locMsg + ", \(index + 1) of \(buttons.count)"
            button.addTarget(self,
                             action: #selector(self.selectedThis(_:)),
                             for: UIControlEvents.touchUpInside)
            if !enabled {
                button.isEnabled = false
            }
            button.tag = tag.id
        }
    }

    // MARK: Audio layout
    func displayPreviewAudio() {
        audioButton.accessibilityLabel = "Preview audio"
        audioButton.accessibilityHint = "Tap to preview your audio"

        let sec = elapsed
        let secStr = sec < 10 ? "0\(sec)" : "\(sec)"
        progressLabel.text = "00:\(secStr)"
        progressLabel.accessibilityLabel = "\(secStr) seconds"
        progressLabel.accessibilityHint = "Length of your recording"
        audioButton.setImage(UIImage(named: "playContribute"), for: UIControlState())
        //TODOnow fix upload undo index order
        //TODOnow fix upload under sizing
    }

    func displayStopPlayback() {
        audioButton.accessibilityLabel = "Stop playback"
        audioButton.accessibilityHint = "Tap to stop playback"

        audioButton.setImage(UIImage(named: "stop"), for: UIControlState())
    }

    func displayStopRecording() {
        audioButton.accessibilityLabel = "Stop recording"
        audioButton.accessibilityHint = "Tap to stop recording"

        audioButton.setImage(UIImage(named: "stop"), for: UIControlState())
    }

    func displayRecordAudio() {
        audioButton.accessibilityLabel = "Record audio"
        audioButton.accessibilityHint = "Tap to record audio"

        audioButton.setImage(UIImage(named: "record"), for: UIControlState())

        let duration = 0.1
        UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
            self.audioButton.isEnabled = true
            self.progressLabel.isHidden = false
            self.progressLabel.text = "00:30"
            self.progressLabel.accessibilityLabel = "30 seconds"
            self.progressLabel.accessibilityHint = "Max recording length"
            }, completion: { finished in
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.audioButton);
        })

    }

    // MARK: Text layout
    func keyboardWillShow(_ sender: Notification) {
        let userInfo: [AnyHashable: Any] = sender.userInfo!
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        let offset: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue.size

//        debugPrint("keyboardSize \(keyboardSize)")
//        debugPrint("offset \(offset)")
        if (self.responseTextView.text == "Your response here"){
            self.responseTextView.text = ""
        }

        if keyboardSize.height == offset.height {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.view.frame.origin.y -= keyboardSize.height
            })
        } else {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.view.frame.origin.y += keyboardSize.height - offset.height
            })
        }
    }

    func keyboardWillHide(_ sender: Notification) {
        let userInfo: [AnyHashable: Any] = sender.userInfo!
        let keyboardSize: CGSize = (userInfo[UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue.size
        self.view.frame.origin.y += keyboardSize.height
        self.viewModel.uploadText = self.responseTextView.text
        self.uploadButton.isHidden = false
        self.undoButton.isHidden = false
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.uploadButton);
    }

    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }


    // MARK: RWFramework Protocol

    /// Sent when the framework determines that recording is possible (via config)
    func rwReadyToRecord(){
        DebugLog("ready to record")
    }

    var elapsed = 0
    func rwRecordingProgress( percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        let dt = maxDuration - (percentage*maxDuration)
        let sec = Int(dt.truncatingRemainder(dividingBy: 60.0))
        elapsed = Int(maxDuration) - sec - 1 // fudging
        let secStr = sec < 10 ? "0\(sec)" : "\(sec)"
        progressLabel.text = "00:\(secStr)"
        progressLabel.accessibilityLabel = "\(secStr) seconds"
        progressLabel.accessibilityHint = "Length of your recording"

    }

    func rwAudioRecorderDidFinishRecording() {
        displayPreviewAudio()
        self.undoButton.isHidden = false
        self.uploadButton.isHidden = false
    }

    func rwPlayingBackProgress( percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
        let dt = (percentage*duration)
        let sec = Int(dt.truncatingRemainder(dividingBy: 60.0))
        let secStr = sec < 10 ? "0\(sec)" : "\(sec)"
        progressLabel.text = "00:\(secStr)"
        progressLabel.accessibilityLabel = "\(secStr) seconds"
        progressLabel.accessibilityHint = "Elapsed time"

    }

    func rwAudioPlayerDidFinishPlaying() {
//        let rwf = RWFramework.sharedInstance
//        displayPreviewAudio()
        DebugLog("stopped playing")
        displayPreviewAudio()
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.uploadButton);

    }

    func rwPostEnvelopesSuccess( data: NSData?){
        DebugLog("post envelope success")
    }

    /// Sent in the case that the server can not return a new envelope id
    func rwPostEnvelopesFailure( error: NSError?){
        DebugLog("post envelope failure")
        SVProgressHUD.dismiss()
        //TODOnow display alert
        //TODOnow trigger undo

    }

    func rwPatchEnvelopesIdSuccess( data: NSData?){
    /// Sent in the case that the server can not accept an envelope item (media upload)
        DebugLog("patch envelope success")
        SVProgressHUD.dismiss()

        //TODO now mark uiitems as contributed
        for (_, tag) in self.viewModel.tags.enumerated(){
            dump(tag)
        }

        self.performSegue(withIdentifier: "Thanks", sender: nil)
    }

    func rwPatchEnvelopesIdFailure( error: NSError?){
        DebugLog("patch envelope failure")
        SVProgressHUD.dismiss()
        //TODO trigger undo
    }

//
//    func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String) {
//        print(path)
//        print(info)
//        let rwf = RWFramework.sharedInstance
//        rwf.setImageDescription(path, description: "Hello, This is an image!")
//    }
//


    // MARK: UITextView Protocol

    func textViewDidBeginEditing(_ textView: UITextView) {
        DebugLog("began editing")
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        DebugLog("finished editing")
        if textView.text.isEmpty {
            textView.text = "Your response here"
            textView.textColor = UIColor.lightGray
        }
    }
}
