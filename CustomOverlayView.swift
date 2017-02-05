//
//  CustomOverlayView.swift
//  testapp2
//
//  Created by Loic Sillere on 25/11/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

import UIKit

protocol CustomOverlayDelegate{
    func didCancel(overlayView:CustomOverlayView)
    func didShoot(overlayView:CustomOverlayView)
    func didStop(overlayView:CustomOverlayView)
}

class CustomOverlayView: UIView {
    var delegate:CustomOverlayDelegate! = nil
    
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var progressTimelapseCreation: UILabel!
    @IBOutlet weak var progressViewTimelapseCreation: UIProgressView!
    @IBOutlet weak var cameraLabel: UILabel!
    
    @IBAction func shootButton(_ sender: UIButton) {
        //cameraLabel.text = "Even Cooler Camera"
        delegate.didShoot(overlayView: self)
        self.shootButton.isEnabled = false
        self.shootButton.isHidden = true
        self.stopButton.isEnabled = true
        self.stopButton.isHidden = false
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        delegate.didCancel(overlayView: self)
    }
    
    @IBAction func stopButton(_ sender: UIButton) {
        delegate.didStop(overlayView: self)
        self.stopButton.isEnabled = false
        self.stopButton.isHidden = true
        //self.shootButton.isEnabled = true
        //self.shootButton.isHidden = false
        self.cameraLabel.isHidden = true
        self.progressViewTimelapseCreation.isHidden = false
        self.progressTimelapseCreation.isHidden = false
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
