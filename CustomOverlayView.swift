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
}

class CustomOverlayView: UIView {
    @IBOutlet weak var shootButton: UIButton!
    
    var delegate:CustomOverlayDelegate! = nil
    
    @IBOutlet weak var cameraLabel: UILabel!
    @IBAction func shootButton(_ sender: UIButton) {
        //cameraLabel.text = "Even Cooler Camera"
        delegate.didShoot(overlayView: self)
        self.shootButton.isEnabled = false
    }
    @IBAction func cancelButton(_ sender: UIButton) {
        cameraLabel.text = "I want to exit"
        delegate.didCancel(overlayView: self)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
