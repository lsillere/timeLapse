//
//  BuildTimeLapseViewController.swift
//  testapp2
//
//  Created by Loic Sillere on 26/11/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

// USELESS ????

import UIKit
import AVFoundation

class BuildTimeLapseViewController: UIViewController {
    
    @IBOutlet weak var noVideoMessage: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    //@IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {

        super.viewDidLoad()
        // Video thumbnail positions
        var y: CGFloat = 65
        var counter:Int = 1
        let separatorPixelSize:CGFloat = 6
        
        let widthVideo = self.view.frame.size.width
        let heightVideo = self.view.frame.size.width * 0.66
        let widthVideoSmall = (self.view.frame.size.width / 3) - (separatorPixelSize/2)
        let heightVideoSmall = widthVideoSmall * 0.66
        
       // let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/TimeLapseVideo"))
        
        // Show existing video thumbnail
        do {
            // Get the directory contents urls of time lapse videos (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: videoOutputURL, includingPropertiesForKeys: nil, options: [])
            
            if(directoryContents.isEmpty) { // No video in folder -> print message
                self.noVideoMessage.text = "Aucune video"
            } else { // Video(s) in folder -> show videos thumbnail
                print(directoryContents[0])
                for element in directoryContents
                {
                    let asset = AVURLAsset(url: element, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    do {
                        // Génère un thumbnail de la vidéo
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        let uiImage = UIImage(cgImage: cgImage)
                        var image = UIImageView(image: uiImage)
                    
                    /* Test avec une image
                    let data = NSData(contentsOf:element)
                    let uiImage = UIImage(data: data as! Data)
                    let imageView.image = UIImageView(image: uiImage)
                    imageView.image = uiImage
                    var label = UILabel(frame: CGRectMake(0, number, 200, 21))*/
                        
                        // Showing Video Thumbnail
                        if(counter == 1) { // First video is shown differently                           
                            image.frame = CGRect(x: 0, y: y, width: widthVideo, height: heightVideo)
                            scrollView.contentSize = CGSize(width: widthVideo, height: y+heightVideo)
                            y = y + heightVideo + separatorPixelSize
                        } else {
                            let imageXPosition = CGFloat((counter+1)%3)*(widthVideoSmall+separatorPixelSize)
                            image.frame = CGRect(x: imageXPosition, y: y, width: widthVideoSmall, height: heightVideoSmall)
                            if((counter+1)%3 == 2) {
                                let imageYPosition = y + heightVideoSmall
                                scrollView.contentSize = CGSize(width: widthVideo, height: imageYPosition)
                                y = y + heightVideoSmall + separatorPixelSize
                            }
                        }
                        scrollView.addSubview(image)
                        counter += 1
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }
            }
            
            // !! check the error before proceeding
            
            // if you want to filter the directory contents you can do like this:
            /*let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            print("mp3 urls:",mp3Files)
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            print("mp3 list:", mp3FileNames)*/
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createTimeLapse(_ sender: Any) {
        
        print("Create Time Lapse")
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



public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
