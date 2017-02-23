//
//  ParameterTimeLapseViewController.swift
//  testapp2
//
//  Created by Loic Sillere on 01/12/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

import UIKit

class ParameterTimeLapseViewController: UIViewController/*, UITableViewDelegate, UITableViewDataSource*/ {
    
    @IBOutlet weak var parameterTableView: UITableView!
    
    let settings = Settings()
    let defaults: UserDefaults = UserDefaults.standard
    
    @IBOutlet weak var vitessSegmentedControll: UISegmentedControl!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    @IBAction func githubLink(_ sender: Any) {
        UIApplication.shared.open(NSURL(string: "http://github.com/lsillere")! as URL, options: [:], completionHandler: nil)
    }
    
    @IBAction func sendFeedback(_ sender: Any) {
        let email = "loic.sillere@gmail.com"
        let url = NSURL(string: "mailto:\(email)")
        UIApplication.shared.open(url as! URL, options: [:], completionHandler: nil)
    }
    
    @IBAction func segmentedControlAction(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            settings.videoQuality = "480p"
        case 1:
            settings.videoQuality = "720p"
        case 2:
            settings.videoQuality = "1080p"
        default:
            settings.videoQuality = ""
        }
        settings.saveData()
        //settings.setVideoQuality(videoQuality: videoQuality)
        
        /*if(segmentedControl.selectedSegmentIndex == 0) {
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
        getData()*/
    }
    
    @IBAction func vitessSegmentedControll(_ sender: Any) {
        switch vitessSegmentedControll.selectedSegmentIndex {
        case 0:
            settings.interval = "8"
        case 1:
            settings.interval = "5"
        case 2:
            settings.interval = "1"
        default:
            settings.interval = ""
        }
        settings.saveData()
        
        /*if(vitessSegmentedControll.selectedSegmentIndex == 0) {
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
        saveData(value: interval, key: "interval")*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*getData()
        videoQuality = settings.videoQuality
        interval = settings.interval*/
        
        switch settings.videoQuality {
        case "480p":
            segmentedControl.selectedSegmentIndex = 0
        case "1080p":
            segmentedControl.selectedSegmentIndex = 2
        default:
            segmentedControl.selectedSegmentIndex = 1
        }
        /*if(settings.videoQuality == "480p") {
            segmentedControl.selectedSegmentIndex = 0
        } else if(settings.videoQuality == "1080p") {
            segmentedControl.selectedSegmentIndex = 2
        } else { // Defaul value 720p
            segmentedControl.selectedSegmentIndex = 1
        }*/
        
        switch settings.interval {
        case "5":
            vitessSegmentedControll.selectedSegmentIndex = 1
        case "8":
            vitessSegmentedControll.selectedSegmentIndex = 0
        default:
            vitessSegmentedControll.selectedSegmentIndex = 2
        }
        
        /*if(settings.interval == "5") {
            vitessSegmentedControll.selectedSegmentIndex = 1
        } else if(settings.interval == "8") {
            vitessSegmentedControll.selectedSegmentIndex = 0
        } else { // Defaul value 1s
            vitessSegmentedControll.selectedSegmentIndex = 2
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*func saveData(value: String, key: String) {
 
        do {
            try defaults.removeObject(forKey: key)
        } catch let error as NSError {
            print(error.localizedDescription)
        }

        defaults.set(value, forKey: key)
        defaults.synchronize()
    }*/
    /*
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
    }*/
    
    /*func numberOfSections(in tableView: UITableView) -> Int {
        return parameterItemTitle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = parameterTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = parameterItem[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
