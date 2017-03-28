//
//  MapViewController.swift
//  Digita11y
//
//  Created by Christopher Reed on 3/12/16.
//  Copyright © 2016 Roundware. All rights reserved.
//

import UIKit
class MapViewController: BaseViewController {
    var viewModel: MapViewModel!

    // MARK: Outlets and Actions

    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func close(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "closeMap", sender: sender)
    }


    // MARK: View
    override func viewDidLoad() {
        self.viewModel = MapViewModel(data: self.rwData!)

        super.viewDidLoad()
        
        let url = URL(string: self.viewModel.mapURL)
        DispatchQueue.global(qos: .default).async {
            if let data = try? Data(contentsOf: url!) {
                if let image = UIImage.init(data: data) {
                    if let rotatedImage = UIImage(cgImage: image.cgImage!, scale: UIScreen.main.scale, orientation: .right) as UIImage? {
                        DispatchQueue.main.async(execute: {
                            self.imageView.image = rotatedImage
                        });
                    }
                }
            }
        }
    }
}
