//
//  ChooseProjectViewController.swift
//  Digita11y
//
//  Created by Christopher Reed on 2/23/16.
//  Copyright © 2016 Roundware. All rights reserved.
//

import UIKit
import RWFramework
import SwiftyJSON

class ChooseProjectViewController: BaseViewController, UIScrollViewDelegate, RWFrameworkProtocol {
    var viewModel: ChooseProjectViewModel!
    var hud: StatusHUD? = StatusHUD.create()
    
    // MARK: Outlets and Actions
    @IBOutlet weak var ProjectsScrollView: UIScrollView!

    @IBAction func selectedThis(_ sender: UIButton) {
        let projectId = sender.tag
        let status = "Loading project data"
        self.hud?.show(string: status)
        if (UIAccessibilityIsVoiceOverRunning()) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status);
        }
        let rwf = RWFramework.sharedInstance
        self.viewModel.selectedProject = self.viewModel.data.getProjectById(projectId)
        rwf.setProjectId(project_id: String(projectId))
        RWFrameworkConfig.setConfigValue(key: "reverse_domain", value: String(describing: self.viewModel.selectedProject?.reverseDomain))
    }


    // MARK: View

    override func viewDidLoad() {
        super.viewDidLoad()

        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(object: self)

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        super.view.addBackground("bg-blue.png")

        self.viewModel = ChooseProjectViewModel(data: self.rwData!)

        //set scroll view for options
        let scroll = ProjectsScrollView
        scroll?.delegate = self
        let titles = self.viewModel.projects.map{$0.name}
        let buttons = self.createButtonsForScroll(titles, scroll: scroll!)

        //set titles and action
        for (index, button) in buttons.enumerated(){
            let project = viewModel.projects[index]
            if(self.viewModel.projects[index].active == false){
                button.isEnabled = false
            }
            button.accessibilityLabel = project.name + ", \(index + 1) of \(buttons.count)"
            button.addTarget(self,
                             action: #selector(ChooseProjectViewController.selectedThis(_:)),
                             for: UIControlEvents.touchUpInside)
            button.tag = project.id
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //hide nav bar on this page
        self.navigationController!.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        //show nav bar everywhere else
        self.navigationController!.setNavigationBarHidden(false, animated: true)
        super.viewWillDisappear(animated);
    }

    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        //correct offset for scrollview
        let scroll = ProjectsScrollView
        let newContentOffsetX = ((scroll?.contentSize.width)! - (scroll?.bounds.size.width)!) / 2
        scroll?.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
    }

    func rwGetProjectsIdSuccess(data: NSData?) {
        _ = JSON(data: data! as Data)
        print("projects id json")
        //TODO update project model and corresponding functionality with info from JSON
//        dump(json)
        self.hud?.hide()
        self.performSegue(withIdentifier: "ProjectSegue", sender: nil)
    }
    func rwGetProjectsIdFailure(error: NSError?) {
        self.hud?.hide()
        DebugLog("project id failure")

    }

}
