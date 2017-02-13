//
//  Settings.swift
//  timeLapse
//
//  Created by Loic Sillere on 02/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit

class Settings {
    var interval: String // interval in second between 2 pictures taken
    var videoQuality: String
    var videoNumber: Int
    var videoName: [String]
    
    // Get var values from userdefault or set default values
    init() {
        let defaults: UserDefaults = UserDefaults.standard
        
        if let videoValue = defaults.string(forKey: "videoQuality") {
            self.videoQuality = videoValue
            print("Video Quality : ", videoQuality)
        } else {
            self.videoQuality = "720P"
        }

        if let interval = defaults.string(forKey: "interval") {
            self.interval = interval
            print("Video interval : ", interval)
        } else {
            self.interval = "1"
        }
        
        self.videoNumber = defaults.integer(forKey: "videoNumber")
        print("videoNumber: ", videoNumber)
        /* {
            self.videoNumber = videoNumber
            print("videoNumber : ", videoNumber)
        } else {
            self.videoNumber = 0
        }*/
    
        if let videoName = defaults.stringArray(forKey: "videoName") {
            self.videoName = videoName
            print("videoName: ", videoName)
        } else {
            videoName = []
        }
    }
    
    
    // Save var in UserDefaults
    func saveData() {
        let defaults: UserDefaults = UserDefaults.standard

        // Save videoQuality
        defaults.removeObject(forKey: "videoQuality")
        defaults.set(self.videoQuality, forKey: "videoQuality")

        // Save interval
        defaults.removeObject(forKey: "interval")
        defaults.set(self.interval, forKey: "interval")
        
        defaults.synchronize()
    }
    
    func saveVideoNumber() {
        let defaults: UserDefaults = UserDefaults.standard
        
        defaults.removeObject(forKey: "videoNumber")
        defaults.set(self.videoNumber, forKey: "videoNumber")
        
        defaults.synchronize()
    }
}
