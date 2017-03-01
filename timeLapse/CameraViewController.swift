//
//  CameraViewController.swift
//  timeLapse
//
//  Created by Loic Sillere on 08/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreData

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, AVCapturePhotoCaptureDelegate {
    var session: AVCaptureSession?
    /* For video
     let cameraOutput: AVCaptureMovieFileOutput? = AVCaptureMovieFileOutput()*/
    var cameraOutput: AVCapturePhotoOutput? = AVCapturePhotoOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var videoOutputURL: URL?
    var videoNumber:Int = 0
    var numberPhotoTaken: Int = 0
    var videoOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    var timer = Timer()
    var timerSecond = Timer()
    let settings = Settings()
    var timeLapseBuilder: TimeLapseBuilder?
    var timerSubview = Timer()
    var videoName:[String] = []
    var orientation: UIImageOrientation = UIImageOrientation.right
    var startTime = Date()
    var backCamera: AVCaptureDevice?
    
    var videoURL: [NSManagedObject] = []
    
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var progressTimelapseCreation: UILabel!
    @IBOutlet weak var videoLibrary: UIButton!
    @IBOutlet weak var progressViewTimelapseCreation: UIView!
    @IBOutlet weak var arrowLabel: UILabel!
    @IBOutlet weak var timeProgressLabel: UILabel!
    @IBOutlet weak var captureProgressLabel: UILabel!
    
    @available(iOS 4.0, *)
    public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("capture did finish")
        print(captureOutput)
        print(videoOutputURL as Any)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let photoPath = getPhotoPath(numberPhotoTaken: numberPhotoTaken)
            FileManager.default.createFile(atPath: photoPath, contents: dataImage, attributes: nil)
            numberPhotoTaken += 1
                        
            UIImageWriteToSavedPhotosAlbum(UIImage(data: dataImage)!, nil, nil, nil)
            print("Capture \(numberPhotoTaken)")
        }
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        /* For video
        videoOutputURL = getFileURL(numberOfVideo: videoNumber)
        let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        cameraOutput?.startRecording(toOutputFileURL: videoOutputURL, recordingDelegate: recordingDelegate)
        print("Start recording")*/
        
        self.shootButton.isEnabled = false
        self.shootButton.isHidden = true
        self.stopButton.isEnabled = true
        self.stopButton.isHidden = false
        self.arrowLabel.isHidden = false
        self.timeProgressLabel.isHidden = false
        self.captureProgressLabel.isHidden = false
        
        print("Start capture")
        let interval: TimeInterval = Double(settings.interval)!
        updateCounter()
        startTime = Date()
        updateTime()
        timer = Timer.scheduledTimer(timeInterval: interval, target:self, selector: #selector(CameraViewController.updateCounter), userInfo: nil, repeats: true)
        timerSecond = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(CameraViewController.updateTime), userInfo: nil, repeats: true)
        
        capturePicture()
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        /* For video
        cameraOutput?.stopRecording()
        print("Stop recording")
        videoNumber += 1*/
        
        self.shootButton.isEnabled = true
        self.shootButton.isHidden = false
        self.stopButton.isEnabled = false
        self.stopButton.isHidden = true

        print("Stop capture")
        timer.invalidate()
        timerSecond.invalidate()
        //buildTimeLapse()
        
        self.performSegue(withIdentifier: "goToCreateTimeLapse", sender: self)
    }
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = previewView.bounds
        
        arrowLabel.backgroundColor = UIColor(patternImage: UIImage(named: "ico-time")!)
        
        /* -------------------------- Create images and videos folder --------------------------- */
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        // Get the Document directory path
        let documentDirectorPath:String = paths[0]
        
        // Create a new path for the new images folder
        let imagesDirectoryPath = documentDirectorPath + "/ImagePicker"
        // If the folder with the given path doesn't exist already, create it
        do{
            try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }catch{
            print("Something went wrong while creating a new folder")
        }
        
        // Create a new path for the new video folder
        let videoDirectoryPath = documentDirectorPath + "/TimeLapseVideo"
        // If the folder with the given path doesn't exist already, create it
        do{
            try FileManager.default.createDirectory(atPath: videoDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }catch{
            print("Something went wrong while creating a new folder")
        }
        /* ------------------------------------------------------------------------------------- */
 
        removeImages() // Delete images if exists
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("VideoQuality \(settings.videoQuality)")
        print("Interval \(settings.interval)")
        
        // Navigation bar customization
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController?.toolbar.tintColor = UIColor.black
        
        cameraOutput = AVCapturePhotoOutput()
        
        
        videoNumber = settings.videoNumber
        
        session = AVCaptureSession()
        
        /*For video
         session?.sessionPreset = AVCaptureSessionPresetHigh*/
        backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            // if need high resolution cameraOutput?.isHighResolutionCaptureEnabled = true
            if (session?.canAddOutput(cameraOutput))! {
                session?.addOutput(cameraOutput)
            }
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async {
            self.videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        videoPreviewLayer!.frame = self.view.bounds
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        previewView.layer.addSublayer(videoPreviewLayer!)
        session!.startRunning()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let videoCount = getVideoCount()
        if(videoCount > 0) {
            videoLibrary.isHidden = false
        }
        videoLibrary.setTitle(String(videoCount), for: .normal)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // For video
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!){
        
        print("capture did finish")
        print(captureOutput);
        print(outputFileURL);
    }
    
    func  getFileURL(numberOfVideo: Int) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let fileName = "video"+String(numberOfVideo)+".mp4";
        videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/TimeLapseVideo/"+fileName))
        
        return videoOutputURL!
    }

    func capturePicture(){
        if (cameraOutput?.connection(withMediaType: AVMediaTypeVideo)) != nil {
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                kCVPixelBufferWidthKey as String: 300,
                kCVPixelBufferHeightKey as String: 300
            ]
            if let photoOutputConnection = cameraOutput?.connection(withMediaType: AVMediaTypeVideo) {
                photoOutputConnection.videoOrientation = videoOrientation
            }
                
            settings.previewPhotoFormat = previewFormat
            settings.isAutoStillImageStabilizationEnabled = true
            // if high resolution needed settings.isHighResolutionPhotoEnabled = true
            cameraOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        }
    }
    
    func  getPhotoURL(numberPhotoTaken: Int) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let fileName = String(numberPhotoTaken)+".jpg";
        let photoURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/ImagePicker/"+fileName))
        
        return photoURL
    }
    
    func  getPhotoPath(numberPhotoTaken: Int) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let fileName = String(numberPhotoTaken)+".jpg";
        let photoDirectoryPath = documentsPath[0] + "/ImagePicker/" + fileName
        
        return photoDirectoryPath
    }
    
    
    func updateVideoOrientationForDeviceOrienration() {
    /*if let videoPreviewLayerConnection = videoPreviewLayer.connection {
    let deviceOrientation = UIDevice.current.orientation
    guard let newVideoOrientation = orientationMap[deviceOrientation],
    deviceOrientation.isPortrait || deviceOrientation.isLandscape
    else { return }
    videoPreviewLayerConnection.videoOrientation = newVideoOrientation*/
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.landscapeLeft :
            print("landscape left")
            orientation = UIImageOrientation.up
            videoOrientation = AVCaptureVideoOrientation.landscapeRight
        case UIDeviceOrientation.landscapeRight :
            print("landscape right")
            videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            orientation = UIImageOrientation.up
        case UIDeviceOrientation.portrait :
            print("portrait")
            orientation = UIImageOrientation.right
            videoOrientation = AVCaptureVideoOrientation.portrait
        case UIDeviceOrientation.portraitUpsideDown :
            print("portraitUpsideDown")
            orientation = UIImageOrientation.right
            videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            print("error")
        }
        DispatchQueue.main.async {
            self.videoPreviewLayer!.connection?.videoOrientation = self.videoOrientation
            self.videoPreviewLayer!.frame = self.view.bounds
        }
        
    }
    /*DispatchQueue.main.async {
    self.previewView.updateVideoOrientationForDeviceOrientation()
    }*/

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateVideoOrientationForDeviceOrienration()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        //touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touchPoint = touches.first! as UITouch
        let screenSize = previewView.bounds.size
        let focusPoint = CGPoint(x: (touchPoint.location(in: previewView).y / screenSize.height), y: (1.0 - touchPoint.location(in: previewView).x / screenSize.width))
        
        if let device = backCamera {
            do {
                try device.lockForConfiguration()
            } catch {
                print("error autofocus not critical")
                return
            }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = AVCaptureFocusMode.autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureExposureMode.autoExpose
            }
            device.unlockForConfiguration()
            
            /*------------------- Add imageview to show where focus is made ------------------- */
            /*removeSubview()
            var imageViewShow : UIImageView
            //print(" focusPoint : ", focusPoint, screenSize.width, screenSize.height)
            imageViewShow  = UIImageView(frame:CGRect(x: (1-focusPoint.y) * screenSize.width, y: focusPoint.x * screenSize.height, width: 60, height: 60))
            imageViewShow.image = UIImage(named:"ico-galery.png")
            imageViewShow.tag = 1
            self.view.addSubview(imageViewShow)
            timerSubview = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(CameraViewController.removeSubview), userInfo: nil, repeats: true)*/
        }
    }
    
    func removeSubview() {
        timerSubview.invalidate()
        
        if let viewWithTag = self.view.viewWithTag(1) {
            viewWithTag.removeFromSuperview()
        } else {
            print("View doesn't exist")
        }
    }
    
    func updateCounter() {
        capturePicture()
    }

    
    func getVideoName() -> [String] {
        let defaults: UserDefaults = UserDefaults.standard
        var videoName:[String] = []
        if let name = defaults.stringArray(forKey: "videoName") {
            videoName = name
        }
        
        return videoName
    }
    
    func saveVideoName(value: [String], key: String) {
        let defaults: UserDefaults = UserDefaults.standard
        
        do {
            try defaults.removeObject(forKey: key)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        defaults.set(value, forKey: key)
        defaults.synchronize()
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
    
    func getVideoCount() -> Int {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let videoDirectoryPath = documentsPath[0] + "/TimeLapseVideo/"
        let videoCount: Int
        
        do {
            videoCount = try FileManager.default.contentsOfDirectory(atPath: videoDirectoryPath).count
        } catch let error as NSError {
            print(error.localizedDescription)
            videoCount = 0
        }

        return videoCount
    }
    
    func buildTimeLapse() {
        // affichage progression
        self.progressViewTimelapseCreation.isHidden = false
        self.progressTimelapseCreation.isHidden = false
        
        /*let videoName = getVideoName()
        print("video Number : ", settings.videoNumber)*/
        let photoPath = getPhotosPath()
        
        self.timeLapseBuilder = TimeLapseBuilder(photoURLs: photoPath, orientation: orientation, videoNumber: settings.videoNumber)
        
        self.settings.videoNumber += 1
        self.settings.saveVideoNumber()
        
        self.timeLapseBuilder!.build(
            { (progress: Progress) in
                NSLog("Progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
                DispatchQueue.main.async {
                    let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                    //progressViewTimelapseCreation.setProgress(progressPercentage, animated: true)
                    let progressPercentageText:String = String(progressPercentage*100) + "%"
                    self.progressTimelapseCreation.text = progressPercentageText
                }
        },
            success: { url in
                NSLog("Output written to \(url)")
                // remove images for memory
                print("Remove images")
                self.removeImages()
                self.saveVideoURL(url: String(describing: url))
                // update video number in link to video library
                DispatchQueue.main.async {
                    let videoCount = self.getVideoCount()
                    self.videoLibrary.setTitle(String(videoCount), for: .normal)
                }
        },
            failure: { error in
                NSLog("failure: \(error)")
                /*dispatch_async(dispatch_get_main_queue(), {
                 progressHUD.dismiss()
                 })*/
        }
        )
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
    
    func updateTime() {
        
        var elapsedTime = Date().timeIntervalSince(startTime)
        
        //calculate hours
        let hours = Int(elapsedTime / 3600.0)
        elapsedTime -= TimeInterval(hours) * 3660
        
        //calculate minutes
        let minutes = Int(elapsedTime / 60.0)
        elapsedTime -= TimeInterval(minutes) * 60
        
        //calculate seconds
        let seconds = Int(elapsedTime)
        //add the leading zero for minutes, seconds and millseconds and store them as string constants
        
        //let strHours = String(format: "%02d", hours)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        
        let resultMinutes = Int((numberPhotoTaken+1) / 30 / 60)
        let resultSeconds = Int(((numberPhotoTaken+1) / 30) - (resultMinutes * 60))
        let strResultMinutes = String(format: "%02d", resultMinutes)
        let strResultSeconds = String(format: "%02d", resultSeconds)
        
        timeProgressLabel.text = "\(strMinutes):\(strSeconds)"
        captureProgressLabel.text = "\(strResultMinutes):\(strResultSeconds)"
        
    }
    
    
    func saveVideoToGallery(videoURL: URL) {
        var videoAssetPlaceholder: PHObjectPlaceholder!
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            videoAssetPlaceholder = request!.placeholderForCreatedAsset
        }, completionHandler: { (success, error) in
            if success {
                let localID = videoAssetPlaceholder.localIdentifier
                print("saved : ", localID)
                let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                if result.firstObject!.mediaType == .video {
                    PHImageManager.default().requestAVAsset(forVideo: result.firstObject!, options: nil, resultHandler: {(asset: AVAsset?,_,_) in
                        
                        if let urlAsset = asset as? AVURLAsset {
                            let localVideoUrl = urlAsset.url as NSURL
                            
                            print("URL : ", localVideoUrl)
                            //completionHandler(responseURL : localVideoUrl)
                            self.saveVideoURL(url: String(describing: localVideoUrl))
                            /* let player = AVPlayer(url: localVideoUrl as URL)
                            let playerViewController = AVPlayerViewController()
                            playerViewController.player = player
                            self.present(playerViewController, animated: true) {
                                playerViewController.player!.play()
                            }*/
                            
                        } else {
                            //completionHandler(responseURL : nil)
                        }
                    })
                }
            }
            else {
                print("error")
            }
        })
    }
    
    func saveVideoURL(url: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        print("url : ", url)
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let entity =
            NSEntityDescription.entity(forEntityName: "Video",
                                       in: managedContext)!
        
        let video = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        video.setValue(url, forKeyPath: "url")
        
        do {
            try managedContext.save()
            videoURL.append(video)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func getVideoURL() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Video")
        
        do {
            videoURL = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
