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

// MARK: Actions and Outlets
    @IBAction func selectAudio(sender: AnyObject) {
        //TODO setup audio (for recording, right?)
        if(!self.viewModel.mediaSelected){
            let duration = 0.1
            UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
                self.textButton.hidden = true
                self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc
                self.tagLabel.hidden = false
                self.tagLabel.text = self.viewModel.itemTag.value
                self.audioButton.enabled = false
            }, completion: { finished in
            })
            
            showTags()
            
            viewModel.mediaType = MediaType.Audio
            viewModel.mediaSelected = true
        } else {
            if(self.viewModel.tagsSelected){
            //record, play, stop
                var rwf = RWFramework.sharedInstance
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

    @IBAction func selectText(sender: AnyObject) {
        if(!self.viewModel.mediaSelected){

            let duration = 0.1
            UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
                self.audioButton.hidden = true
                self.ContributeAsk.text = "What do you want to speak about?"
                self.tagLabel.text = "Text"
                self.textButton.enabled = false
                }, completion: { finished in
            })
            
            showTags()

            viewModel.mediaType = MediaType.Text
            self.viewModel.mediaSelected = true
        }
    }
    
    @IBAction func selectedThis(sender: AnyObject) {
        let scroll = ContributeScroll
        let others = scroll.subviews.filter({$0 as UIView != sender as! UIView})
        for (index, button) in others.enumerate(){
            button.hidden = true
        }
        
        //set tag into viewmodel
        self.viewModel.selectedTag = self.viewModel.data.getTagById(sender.tag)
        if(!self.viewModel.tagsSelected){
            self.ContributeAsk.text = self.viewModel.uiGroup.headerTextLoc
            showTags()
        } else {
            if let button = sender as? UIButton {
                button.enabled = false
            }
            if(viewModel.mediaType == MediaType.Audio){
                setupAudio() { granted, error in
                    if granted == false {
                        debugPrint("Unable to setup audio: \(error)")
                        if let error = error {
                            CLSNSLogv("Unable to setup audio: \(error)", getVaList([error]))
                        }
                    } else {
                        debugPrint("Successfully setup audio")
                        let duration = 0.1
                        UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
                            self.audioButton.enabled = true
                            self.progressLabel.hidden = false
                            self.progressLabel.text = "00:30"
                        }, completion: { finished in
                        })
                    }
                }
            } else {
                //is text
                let duration = 0.1

                UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
                    self.responseTextView.hidden = false
                    self.tagLabel.hidden = true
                    self.textButton.hidden = true
                    self.uploadButton.hidden = false
                }, completion: { finished in
                })
            }
        }
        
    }
        
    @IBAction func cancel(sender: AnyObject) {
        //TODO should go into unwind also
        let rwf = RWFramework.sharedInstance
        if(rwf.hasRecording()){
            rwf.deleteRecording()
        }
        self.performSegueWithIdentifier("cancel", sender: nil)
    }
    
    @IBAction func undo(sender: AnyObject) {
        debugPrint("undoing")
        let rwf = RWFramework.sharedInstance
        if(rwf.hasRecording()){
            rwf.deleteRecording()
            displayRecordAudio()
            let duration = 0.1
            UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
            }, completion: { finished in
                self.undoButton.hidden = true
                self.uploadButton.hidden = true
                self.progressLabel.text = "00:30"
            })
        } else {
            let duration = 0.1
            UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
                }, completion: { finished in
                    self.undoButton.hidden = true
                    self.uploadButton.hidden = true
                    self.responseTextView.hidden = true
                    self.responseTextView.text = "Your response here"
                    self.responseTextView.textColor = UIColor.lightGrayColor()
            })
        }
    }

    @IBAction func upload(sender: AnyObject) {
        let rwf = RWFramework.sharedInstance
//        for image in self.viewModel.images {
//            rwf.setImageDescription(image.path, description: image.text)
//        }
        
//        self.images.removeAll()
//        self.uploadText = ""

        if self.viewModel.uploadText.isEmpty == false {
            rwf.addText(self.viewModel.uploadText)
        } else {
            rwf.addRecording()
        }
        
        debugPrint("uploading")

        rwf.uploadAllMedia(self.viewModel.tagIds)
        SVProgressHUD.showWithStatus("Uploading")

    }

    
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

    
    // MARK: View
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ContributeScroll.hidden = true
        uploadButton.hidden = true
        undoButton.hidden = true
        tagLabel.hidden = true
        progressLabel.hidden = true
        responseLabel.hidden = true
        responseTextView.hidden = true
        responseTextView.returnKeyType = UIReturnKeyType.Done
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        super.view.addBackground("bg-comment.png")
        self.viewModel = ContributeViewModel(data: self.rwData!)
        //TODO make a button image
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(cancel(_:)))
        ContributeAsk.text = "How would you like to contribute to \(self.viewModel.itemTag.value)?"
        
        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(self)
        ContributeScroll.delegate = self
        responseTextView.delegate = self
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Layout work
    func showTags(){
        let scroll = ContributeScroll
        scroll.hidden = false
        scroll.delegate = self

        let tags = self.viewModel.tags
        let total = tags.count
        
        var button  = UIButtonTag(type: UIButtonType.System)
        var buttons : [UIButton] = []
        
        for (_, item) in scroll.subviews.enumerate(){
            item.removeFromSuperview()
        }
        let newContentOffsetX = (button.buttonWidth - scroll.bounds.size.width) / 2
        debugPrint("new content offset \(newContentOffsetX)")
        
        for index in 0..<total {
            button = UIButtonTag(type: UIButtonType.System)
            let indexFloat = CGFloat(index)
            let frame = CGRect(
                x: button.buttonMarginX - newContentOffsetX,
                y: indexFloat * (button.buttonMarginY + button.buttonHeight),
                width: button.buttonWidth,
                height: button.buttonHeight )
            button.frame = frame
            button.titleLabel?.numberOfLines = 0
            buttons.append(button as UIButton)
        }
        
        scroll.contentSize.width = button.buttonWidth
        scroll.contentSize.height = (button.buttonHeight + button.buttonMarginY) * CGFloat(total)
        
        //set titles and actions
        for (index, button) in buttons.enumerate(){
            let tag = tags[index]
            button.setTitle(tag.value, forState: .Normal)
            button.addTarget(self,

                action: #selector(self.selectedThis(_:)),
                forControlEvents: UIControlEvents.TouchUpInside)
            button.tag = tag.id
        }
        
        let duration = 0.1
        UIView.animateWithDuration(duration, delay: 0, options: [], animations: {
            for (index, button) in buttons.enumerate(){
                scroll.addSubview(button)
            }
        }, completion: { finished in
        })

    }
//
    func displayPreviewAudio() {
        audioButton.accessibilityLabel = "Preview audio"
//        progressView.progress = 0.0
        audioButton.setImage(UIImage(named: "playContribute"), forState: .Normal)
    }
    
    func displayStopPlayback() {
        audioButton.accessibilityLabel = "Stop playback"
        audioButton.setImage(UIImage(named: "stop"), forState: .Normal)
        progressLabel.text = "00:00"
        progressLabel.accessibilityLabel = "0 seconds"
    }
    
    func displayStopRecording() {
        audioButton.accessibilityLabel = "Stop recording"
        audioButton.setImage(UIImage(named: "stop"), forState: .Normal)
    }
    
    func displayRecordAudio() {
        audioButton.accessibilityLabel = "Record audio"
//        progressView.progress = 0.0
        audioButton.setImage(UIImage(named: "record"), forState: .Normal)
        progressLabel.text = "00:30"
        progressLabel.accessibilityLabel = "0 seconds"
    }
    
    
    // MARK: RWFramework Protocol

//
//    func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String) {
//        print(path)
//        print(info)
//        let rwf = RWFramework.sharedInstance
//        rwf.setImageDescription(path, description: "Hello, This is an image!")
//    }
//    
    /// Sent when the framework determines that recording is possible (via config)
    func rwReadyToRecord(){
        debugPrint("ready to record")
    }
    

    func rwRecordingProgress(percentage: Double, maxDuration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        var dt = maxDuration - (percentage*maxDuration)
        var sec = Int(dt%60.0)
        var milli = Int(100*(dt - floor(dt)))
        var secStr = sec < 10 ? "0\(sec)" : "\(sec)"
        progressLabel.text = "00:\(secStr)"
        progressLabel.accessibilityLabel = "\(secStr) seconds"
    }

    
    func rwAudioRecorderDidFinishRecording() {
        displayPreviewAudio()
        self.undoButton.hidden = false
        self.uploadButton.hidden = false
    }
    
    func rwPlayingBackProgress(percentage: Double, duration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        var dt = (percentage*duration)
        var sec = Int(dt%60.0)
        var milli = Int(100*(dt - floor(dt)))
        var secStr = sec < 10 ? "0\(sec)" : "\(sec)"
        progressLabel.text = "00:\(secStr)"
        progressLabel.accessibilityLabel = "\(secStr) seconds"
    }
    
    func rwAudioPlayerDidFinishPlaying() {
//        let rwf = RWFramework.sharedInstance
//        displayPreviewAudio()
        debugPrint("stopped playing")
        displayPreviewAudio()
    }
    
    func rwPostEnvelopesSuccess(data: NSData?){
        debugPrint("post envelope success")
    }
    
    /// Sent in the case that the server can not return a new envelope id
    func rwPostEnvelopesFailure(error: NSError?){
        debugPrint("post envelope failure")
        SVProgressHUD.dismiss()
        //TODO trigger undo

    }

    func rwPatchEnvelopesIdSuccess(data: NSData?){
    /// Sent in the case that the server can not accept an envelope item (media upload)
        debugPrint("patch envelope success")
        SVProgressHUD.dismiss()
        //TODO mark tags as contributed
        self.performSegueWithIdentifier("Thanks", sender: nil)

    }
    
    func rwPatchEnvelopesIdFailure(error: NSError?){
        debugPrint("patch envelope failure")
        SVProgressHUD.dismiss()
        //TODO trigger undo
    }
    
    
    // MARK: UITextView Protocol

    func textViewDidBeginEditing(textView: UITextView) {
        debugPrint("began editing")
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        debugPrint("finished editing")
        if textView.text.isEmpty {
            textView.text = "Your response here"
            textView.textColor = UIColor.lightGrayColor()
        }
    }
}