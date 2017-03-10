//
//  BuildTimeLapseViewController.swift
//  timeLapse
//
//  Created by Loic Sillere on 25/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit

extension UIImageView
{
    func blur()
    {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.addSubview(blurEffectView)
    }
}

/*extension UIView {
    func addImageBackground(image: UIImage) {
        // screen width and height:
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageViewBackground.image = image
        
        // you can change the content mode:
        imageViewBackground.contentMode = UIViewContentMode.scaleAspectFill
        imageViewBackground.blur()
        self.addSubview(imageViewBackground)
        self.sendSubview(toBack: imageViewBackground)
    }
}*/

class CreateTimeLapseViewController: UIViewController {

    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var sucesssVideoSaveLabel: UILabel!
    @IBOutlet weak var successPico: UIImageView!
    @IBOutlet weak var retakeTimeLapseButton: UIButton!
    
    let progressLine = CAShapeLayer()
    let settings = Settings()
    var timeLapseBuilder: TimeLapseBuilder?
    var orientation: UIImageOrientation = UIImageOrientation.right
    var imageBg: UIImage = UIImage()
    var screenSize: CGSize?
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let photoPath = getPhotosPath()
        
        // Do any additional setup after loading the view.
        sucesssVideoSaveLabel.translatesAutoresizingMaskIntoConstraints = true
        screenSize = bgImage.bounds.size
        
        // set up some values to use in the curve
        let ovalStartAngle = CGFloat(90.01 * M_PI/180)
        let ovalEndAngle = CGFloat(90 * M_PI/180)
        let ovalRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        // create the bezier path
        let ovalPath = UIBezierPath()
        
        ovalPath.addArc(withCenter: CGPoint(x: ovalRect.midX, y: ovalRect.midY),
                        radius: ovalRect.width / 2,
                        startAngle: ovalStartAngle,
                        endAngle: ovalEndAngle, clockwise: true)
        
        // create an object that represents how the curve
        // should be presented on the screen
        
        progressLine.path = ovalPath.cgPath
        progressLine.strokeColor = UIColor.white.cgColor
        progressLine.fillColor = UIColor.clear.cgColor
        progressLine.lineWidth = 3.0
        progressLine.lineCap = kCALineCapRound
        
        progressLine.position = CGPoint(x: (screenSize!.width/2) - 50, y: 150)
        
        // add the curve to the screen
        self.view.layer.addSublayer(progressLine)

        
        
        
        updateVideoOrientationForDeviceOrienration()
        
        if FileManager.default.fileExists(atPath: photoPath[0]) {
            if let imageData = FileManager.default.contents(atPath: photoPath[0]),
                let image = UIImage(data: imageData) {
                bgImage.contentMode = UIViewContentMode.scaleAspectFill
                bgImage.image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: orientation)
                
                //self.view.addImageBackground(image: image)
               
                //bgImage.backgroundColor = UIColor.blue
                bgImage.blur()
                imageBg = image
            } else {
                bgImage.backgroundColor = UIColor.black
            }
        }
        
        updateElementPositionForDeviceOrienration()
        
        buildTimeLapse(photoPath: photoPath)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        updateVideoOrientationForDeviceOrienration()
        bgImage.contentMode = UIViewContentMode.scaleAspectFill
        //bgImage.image = UIImage(cgImage: imageBg.cgImage!, scale: imageBg.scale, orientation: orientation)
        updateElementPositionForDeviceOrienration()
        //bgImage.blur()

    }
    
    @IBAction func recreateTimeLapse(_ sender: UIButton) {
        
        retakeTimeLapseButton.isHidden = true
        successPico.isHidden = true
        let photoPath = getPhotosPath()
        buildTimeLapse(photoPath: photoPath)
    }
        
    func getPhotosPath() -> [String] {
        var contentsPath = [String]()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let photoDirectoryPath = documentsPath[0] + "/ImagePicker/"
        
        do {
            contentsPath = try FileManager.default.contentsOfDirectory(atPath: photoDirectoryPath)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        var cpt:Int = 0
        for elements in contentsPath {
            contentsPath[cpt] = photoDirectoryPath + elements
            cpt += 1
        }
        
        return contentsPath
    }
    
    func animation(toValue: Double, fromValue: Double) {
        
        // create a basic animation that animates the value 'strokeEnd'
        // from 0.0 to 1.0 over 3.0 seconds
        let animateStrokeEnd = CABasicAnimation(keyPath: "strokeEnd")
        animateStrokeEnd.duration = 0
        animateStrokeEnd.fromValue = fromValue
        /*let a: Double = Double(progression)/Double(photoNumber)
        print("a: ", a)*/
        animateStrokeEnd.toValue = toValue
        
        // add the animation
        progressLine.add(animateStrokeEnd, forKey: "animate stroke end animation")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func buildTimeLapse(photoPath: [String]) {
        
        self.timeLapseBuilder = TimeLapseBuilder(photoURLs: photoPath, orientation: orientation, videoNumber: settings.videoNumber)
        
        self.settings.videoNumber += 1
        self.settings.saveVideoNumber()
        var fromValue: Double = 0
        
        self.timeLapseBuilder!.build(
            { (progress: Progress) in
                NSLog("Progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
                DispatchQueue.main.async {
                    let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                    self.animation(toValue: Double(progressPercentage), fromValue: fromValue)
                    fromValue = Double(progressPercentage)
                    /*progressViewTimelapseCreation.setProgress(progressPercentage, animated: true)
                    let progressPercentageText:String = String(progressPercentage*100) + "%"
                    self.progressTimelapseCreation.text = progressPercentageText*/
                }
        },
            success: { url in
                NSLog("Output written to \(url)")
                
                // remove images for memory
                print("Remove images")
                self.removeImages()
                
                DispatchQueue.main.async {
                    self.successPico.isHidden = false
                    self.successPico.image = UIImage(named: "success")
                    self.sucesssVideoSaveLabel.isHidden = false
                }
        },
            failure: { error in
                NSLog("failure: \(error)")
                print("error")
                DispatchQueue.main.async {
                    self.successPico.isHidden = false
                    self.successPico.image = UIImage(named: "cross")
                    self.retakeTimeLapseButton.isHidden = false
                }
        }
        )
    }
    
    func updateVideoOrientationForDeviceOrienration() {
        
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.landscapeLeft :
            print("landscape left")
            orientation = UIImageOrientation.up
        case UIDeviceOrientation.landscapeRight :
            print("landscape right")
            orientation = UIImageOrientation.up
        case UIDeviceOrientation.portrait :
            print("portrait")
            orientation = UIImageOrientation.right
        case UIDeviceOrientation.portraitUpsideDown :
            print("portraitUpsideDown")
            orientation = UIImageOrientation.right
        default:
            print("error detecting orientation => portrait")
            orientation = UIImageOrientation.right
        }
    }
    
    func updateElementPositionForDeviceOrienration() {
        
        print("screenSize: ", screenSize as Any)
        switch orientation {
        case UIImageOrientation.up, UIImageOrientation.upMirrored :
            progressLine.position = CGPoint(x: (screenSize!.height/2) - 50.0,
                                            y: screenSize!.width / 2 - 50 - sucesssVideoSaveLabel.frame.size.height / 2 - 10)
            sucesssVideoSaveLabel.frame = CGRect(x: screenSize!.height/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                                 y: screenSize!.width / 2 + 50 + sucesssVideoSaveLabel.frame.size.height / 2 + 10,
                                                 width: sucesssVideoSaveLabel.frame.size.width,
                                                 height: sucesssVideoSaveLabel.frame.size.height)
            successPico.frame = CGRect(x: screenSize!.height/2 - successPico.frame.size.width/2,
                                       y: (screenSize!.width/2) - 50 - sucesssVideoSaveLabel.frame.size.height / 2,
                                       width: successPico.frame.size.width,
                                       height: successPico.frame.size.height)
            retakeTimeLapseButton.frame = CGRect(x: screenSize!.height/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                                 y: screenSize!.width / 2 + 50 + sucesssVideoSaveLabel.frame.size.height / 2 + 10,
                                                 width: sucesssVideoSaveLabel.frame.size.width,
                                                 height: sucesssVideoSaveLabel.frame.size.height)
            
        case UIImageOrientation.right, UIImageOrientation.rightMirrored :
            progressLine.position = CGPoint(x: (screenSize!.width/2) - 50.0,
                                                                                                 y: (screenSize!.height/2) - 50 - sucesssVideoSaveLabel.frame.size.height / 2 - 10)
            sucesssVideoSaveLabel.frame = CGRect(x: screenSize!.width/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                             y: (screenSize!.height/2) + 50 + sucesssVideoSaveLabel.frame.size.height / 2  + 10,
                                             width: sucesssVideoSaveLabel.frame.size.width,
                                             height: sucesssVideoSaveLabel.frame.size.height)
            successPico.frame = CGRect(x: screenSize!.width/2 - successPico.frame.size.width/2,
                                       y: (screenSize!.height/2) - 50 - sucesssVideoSaveLabel.frame.size.height / 2,
                                       width: successPico.frame.size.width,
                                       height: successPico.frame.size.height)
            retakeTimeLapseButton.frame = CGRect(x: screenSize!.width/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                                 y: (screenSize!.height/2) + 50 + sucesssVideoSaveLabel.frame.size.height / 2  + 10,
                                                 width: sucesssVideoSaveLabel.frame.size.width,
                                                 height: sucesssVideoSaveLabel.frame.size.height)
            
        default:
            progressLine.position = CGPoint(x: (screenSize!.width/2) - 50.0,
                                            y: (screenSize!.height/2) - 50 - sucesssVideoSaveLabel.frame.size.height / 2 - 10)
            sucesssVideoSaveLabel.frame = CGRect(x: screenSize!.width/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                                 y: (screenSize!.height/2) + 50 + sucesssVideoSaveLabel.frame.size.height / 2  + 10,
                                                 width: sucesssVideoSaveLabel.frame.size.width,
                                                 height: sucesssVideoSaveLabel.frame.size.height)
            successPico.frame = CGRect(x: screenSize!.width/2 - successPico.frame.size.width/2,
                                       y: (screenSize!.height/2) - 50 + sucesssVideoSaveLabel.frame.size.height / 2,
                                       width: successPico.frame.size.width,
                                       height: successPico.frame.size.height)
            retakeTimeLapseButton.frame = CGRect(x: screenSize!.width/2 - sucesssVideoSaveLabel.frame.size.width/2,
                                                 y: (screenSize!.height/2) + 50 + sucesssVideoSaveLabel.frame.size.height / 2  + 10,
                                                 width: sucesssVideoSaveLabel.frame.size.width,
                                                 height: sucesssVideoSaveLabel.frame.size.height)
        }
    }
    
    func removeImages() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let photosURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/ImagePicker"))
        
        do {
            let imagesDirectoryContents = try FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil, options: [])
            for element in imagesDirectoryContents {
                do {
                    try FileManager.default.removeItem(at: element)
                } catch {
                    print("Could not delete file") // gestion des erreurs : TO IMPROVE
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
