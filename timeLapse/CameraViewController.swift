//
//  CameraViewController.swift
//  timeLapse
//
//  Created by Loic Sillere on 08/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, AVCapturePhotoCaptureDelegate {
    var session: AVCaptureSession?
    /* For video
     let cameraOutput: AVCaptureMovieFileOutput? = AVCaptureMovieFileOutput()*/
    let cameraOutput: AVCapturePhotoOutput? = AVCapturePhotoOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var videoOutputURL: URL?
    var videoNumber:Int = 0
    var numberPhotoTaken: Int = 0
    var videoOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    var timer = Timer()
    let settings = Settings()
    var timeLapseBuilder: TimeLapseBuilder?
    var videoName:[String] = []
    var orientation: UIImageOrientation = UIImageOrientation.right
    
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var progressTimelapseCreation: UILabel!
    
    @IBOutlet weak var progressViewTimelapseCreation: UIView!
    /*!
     @method captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:
     @abstract
     Informs the delegate when all pending data has been written to an output file.
     
     @param captureOutput
     The capture file output that has finished writing the file.
     @param fileURL
     The file URL of the file that has been written.
     @param connections
     An array of AVCaptureConnection objects attached to the file output that provided the data that was written to the file.
     @param error
     An error describing what caused the file to stop recording, or nil if there was no error.
     
     @discussion
     This method is called when the file output has finished writing all data to a file whose recording was stopped, either because startRecordingToOutputFileURL:recordingDelegate: or stopRecording were called, or because an error, described by the error parameter, occurred (if no error occurred, the error parameter will be nil). This method will always be called for each recording request, even if no data is successfully written to the file.
     
     Clients should not assume that this method will be called on a specific thread.
     
     Delegates are required to implement this method.
     */
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
        
        print("Start capture")
        let interval: TimeInterval = Double(settings.interval)!
        updateCounter()
        timer = Timer.scheduledTimer(timeInterval: interval, target:self, selector: #selector(CameraViewController.updateCounter), userInfo: nil, repeats: true)
        
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
        buildTimeLapse()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = previewView.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoNumber = settings.videoNumber
        print("VideoQuality \(settings.videoQuality)")
        print("Interval \(settings.interval)")

        /*fileName = "mysavefile.mp4";
         let documentsURL = FileManager.default.urls(for: .DocumentDirectory, in: .UserDomainMask)[0]
         filePath = documentsURL.URLByAppendingPathComponent(fileName)*/
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewWillAppear(animated)
        
        session = AVCaptureSession()

        
        /*For video
        session?.sessionPreset = AVCaptureSessionPresetHigh*/
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        
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

    func buildTimeLapse() {
        // affichage progression
        self.progressViewTimelapseCreation.isHidden = false
        self.progressTimelapseCreation.isHidden = false
        
        let videoName = getVideoName()
        print("videoName : ", videoName)
        let photoPath = getPhotosPath()
        
        self.timeLapseBuilder?.removeVideoIfExist()
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
                /*dispatch_get_main_queue().asynchronously(execute: {
                 let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                 progressHUD.setProgress(progressPercentage, animated: true)
                 })*/
        },
            success: { url in
                NSLog("Output written to \(url)")
                /*dispatch_async(dispatch_get_main_queue(), {
                 //progressHUD.dismiss()
                 })*/
                // Save nombre vidéo enregistrés
                self.removeImages()
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
}