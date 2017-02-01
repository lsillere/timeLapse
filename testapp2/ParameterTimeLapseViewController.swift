//
//  ParameterTimeLapseViewController.swift
//  testapp2
//
//  Created by Loic Sillere on 01/12/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

import UIKit

class ParameterTimeLapseViewController: UIViewController {
    
    var videoQuality:String = ""
    var interval:String = "" // interval betwenn 2 pictures which drive vitess of the video
    
    let defaults: UserDefaults = UserDefaults.standard
    
    @IBOutlet weak var vitessSegmentedControll: UISegmentedControl!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentedControlAction(_ sender: Any) {
        // TO IMPROVE
        if(segmentedControl.selectedSegmentIndex == 0) {
            print("First Segment Selected")
            videoQuality = "480p"
        }
        else if(segmentedControl.selectedSegmentIndex == 1) {
            print("Second Segment Selected")
            videoQuality = "720p"
        }
        else if(segmentedControl.selectedSegmentIndex == 2) {
            print("Third Segment Selected")
            videoQuality = "1080p"
        }
        saveData(value: videoQuality, key: "videoQuality")
        //getData()
    }
    
    @IBAction func vitessSegmentedControll(_ sender: Any) {
        // TO IMPROVE
        if(vitessSegmentedControll.selectedSegmentIndex == 0) {
            print("Slow Vitess")
            interval = "8"
        }
        else if(vitessSegmentedControll.selectedSegmentIndex == 1) {
            print("Medium Vitess Segment Selected")
            interval = "5"
        }
        else if(vitessSegmentedControll.selectedSegmentIndex == 2) {
            print("Fast Vitess")
            interval = "1"
        }
        saveData(value: interval, key: "interval")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        if(videoQuality == "480p") {
            segmentedControl.selectedSegmentIndex = 0
        } else if(videoQuality == "1080p") {
            segmentedControl.selectedSegmentIndex = 2
        } else { // Defaul value 720p
            segmentedControl.selectedSegmentIndex = 1
        }
        
        if(interval == "5") {
            vitessSegmentedControll.selectedSegmentIndex = 1
        } else if(interval == "8") {
            vitessSegmentedControll.selectedSegmentIndex = 0
        } else { // Defaul value 1s
            vitessSegmentedControll.selectedSegmentIndex = 2
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveData(value: String, key: String) {
 
        do {
            try defaults.removeObject(forKey: key)
        } catch let error as NSError {
            print(error.localizedDescription)
        }

        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    func getData() {
        if let videoValue = defaults.string(forKey: "videoQuality") {
            videoQuality = videoValue
            print("Video Quality : ", videoQuality)
        }
       // interval = defaults.string(forKey: "interval")!
        if let intervalValue = defaults.string(forKey: "interval") {
            interval = intervalValue
            print("Video interval : ", interval)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
