//
//  ViewController.swift
//  testapp2
//
//  Created by Loic Sillere on 25/11/2016.
//  Copyright © 2016 Loic Sillere. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CustomOverlayDelegate {
    
    var imagesDirectoryPath: String!
    var imagePicker: UIImagePickerController!
    var imageTab: [UIImage] = []
    var imageTest: UIImage!
    var timer = Timer()
    var counterImage: Int = 0
    var imagePath: [String] = []
    var imageURL: [URL] = []
    var timeLapseBuilder: TimeLapseBuilder?
    var cpt:Int = 0
    var customView:CustomOverlayView!
    var videoNumber:Int = 0
    var videoName:[String] = []
   // var compressedJPGImage: UIImage
    
    @IBOutlet weak var imageView: UIImageView!
    
    // Encore d'actu ?
    @IBAction func savePhoto(_ sender: Any) {
        //var imageData = UIImageJPEGRepresentation(imageView.image!, 0.6)
        //var compressedJPGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
        
        let alertVC = UIAlertController(
            title: "Save",
            message: "Réussi",
            preferredStyle: .alert)
        let okSave = UIAlertAction(
            title: "OK",
            style:.default,
            handler: nil)
        alertVC.addAction(okSave)
        present(
            alertVC,
            animated: true,
            completion: nil)

    }
    
    // Test afichage image et taille - à retirer avan soumission
    @IBAction func testAction(_ sender: Any) {
        let dataNew = FileManager.default.contents(atPath: imagePath[cpt])
        let imageTest = UIImage(data: dataNew!)
        imageView.image = imageTest
        print("Width:", imageTest?.size.width)
        print("Height:", imageTest?.size.height)
        /*switch imageTest?.imageOrientation {
        case UIImageOrientation.up:
            print("up")
        case UIImageOrientation.down:
            print("down")
        case UIImageOrientation.right:
            print("right")
        case UIImageOrientation.down:
            print("left")
        default:
            print("error")
        }*/
        if(imageTest?.imageOrientation == UIImageOrientation.up) {
            print("up")
        } else if(imageTest?.imageOrientation == UIImageOrientation.down) {
            print("down")
        } else if(imageTest?.imageOrientation == UIImageOrientation.right) {
            print("right")
        } else if (imageTest?.imageOrientation == UIImageOrientation.left) {
            print("left")
        }

        cpt += 1
    }
    
    // Création de la timelapse
    @IBAction func timeLapse(_ sender: Any) {
        videoNumber = getData() // Nombre de vidéo enregistrées (A RECUPERER AU LANCEMENT DE L'APPLI EN VAR GLOBALE)
        print("videoNumber : ", videoNumber)
        
        videoName = getVideoName()
        print("videoName : ", videoName)
        
        self.timeLapseBuilder = TimeLapseBuilder(photoURLs: imagePath, orientation: (imageView.image?.imageOrientation)!, videoNumber: videoNumber)
        self.timeLapseBuilder!.build(
            { (progress: Progress) in
                NSLog("Progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
                DispatchQueue.main.async {
                    let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                }
                /*dispatch_get_main_queue().asynchronously(execute: {
                    let progressPercentage = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
                    //progressHUD.setProgress(progressPercentage, animated: true)
                })*/
        },
            success: { url in
                NSLog("Output written to \(url)")
                self.videoNumber += 1
                /*dispatch_async(dispatch_get_main_queue(), {
                    //progressHUD.dismiss()
                })*/
                // Save nombre vidéo enregistrés
                self.saveData(value: self.videoNumber, key: "videoNumber")
                self.videoName.append("AssembledVideo"+String(self.videoNumber-1)+".mov")
                self.saveVideoName(value: self.videoName, key: "videoName")
        },
            failure: { error in
                NSLog("failure: \(error)")
                /*dispatch_async(dispatch_get_main_queue(), {
                    progressHUD.dismiss()
                })*/
        }
        )
    }
    
    // Lecture de la dernière vidéo "time lapsé"
    // GESTION DE VIDEOPATH ET VIDEOURL WTF !!! -> à mettre en ordre on comprend rien
    @IBAction func playTimeLapse(_ sender: Any) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/TimeLapseVideo/AssembledVideo"+String(videoNumber-1)+".mov"))
        let videoOutputPath = (documentsPath as String) + "/TimeLapseVideo/AssembledVideo.mov"
        print("videoOutputURL :", videoOutputURL)
        print(videoOutputPath)

        let testExist = FileManager.default.fileExists(atPath: videoOutputPath)
        print(testExist)
        let player = AVPlayer(url: videoOutputURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
        //UISaveVideoAtPathToSavedPhotosAlbum(videoOutputPath as String, self, "savingCallBack:didFinishSavingWithError:contextInfo:", nil)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
            imagePicker =  UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.delegate = self
            imagePicker.showsCameraControls = false
            
            let customViewController = CustomOverlayViewController(
                nibName:"CustomOverlayViewController",
                bundle: nil
            )
            self.customView = customViewController.view as! CustomOverlayView
            self.customView.frame = self.imagePicker.view.frame
            //customView.cameraLabel.text = "Hello Camera"
            self.customView.delegate = self

            present(imagePicker, animated: true, completion: {
                self.imagePicker.cameraOverlayView = self.customView
            })
            //present(imagePicker, animated: true, completion: nil) // Caméra classique
        }
        else { //no camera found -- alert the user.
            let alertVC = UIAlertController(
                title: "No Camera",
                message: "Sorry, this device has no camera",
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: "OK",
                style:.default,
                handler: nil)
            alertVC.addAction(okAction)
            present(
                alertVC,
                animated: true,
                completion: nil)
        }
    }
    
    
    @IBAction func removeVideoAction(_ sender: Any) {
        removeImages()
        print("Images deleted")
    }
    
    
    
    
    
    func removeImages() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/ImagePicker"))
        
        do {
            let imagesDirectoryContents = try FileManager.default.contentsOfDirectory(at: videoOutputURL, includingPropertiesForKeys: nil, options: [])
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
    
    // action une fois que la photo est prise
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // retrait de la vue photo
        //imagePicker.dismiss(animated: true, completion: nil)
        
        //imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // sauvegarde de l'image dasn un array
        //imageTab.append(imageView.image!)
        
        // sauvegarde de l'image dans la library
        //UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
        //imageURL = info[UIImagePickerControllerReferenceURL] as! NSString
        //let imageName = imageURL.lastPathComponent
        //let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        //let localPath = documentDirectory.stringByAppendingPathComponent(imageName)
        //print(localPath)*/
        
        let imageDeTest = info[UIImagePickerControllerOriginalImage] as? UIImage
        let testimg: String = imagesDirectoryPath + "/" + String(counterImage+1) + ".jpg"
        imagePath.append(testimg)
        let data = UIImageJPEGRepresentation(imageDeTest!, 1.0)
        FileManager.default.createFile(atPath: imagePath[counterImage], contents: data, attributes: nil)
        
        
        let dataNew = FileManager.default.contents(atPath: imagePath[counterImage])
        let imageTest = UIImage(data: dataNew!)
        imageView.image = imageTest
        print("imagePath : ", imagePath[counterImage])
        //let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        //imagePath[counterImage-1] = URL(fileURLWithPath: documentsPath.appendingPathComponent("ImagePicker/" + String(counterImage) + ".jpg")).absoluteString
        //imagePath[counterImage-1] =
        /*imageURL.append(URL(fileURLWithPath: documentsPath.appendingPathComponent("ImagePicker/" + String(counterImage) + ".jpg")))
        print("ImageURL :", imageURL[0])*/
        counterImage += 1
        print(counterImage)
        self.customView.cameraLabel.text = String(counterImage) + " -> " + String(counterImage/30) + "s"
        //UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
        //print("UIImage : ", imageView.image)
    }
    
    // Cancel photo -> spot la capture
    func didCancel(overlayView:CustomOverlayView) {
        timer.invalidate()
        imagePicker.dismiss(animated: true, completion: nil)
        
        //------------------------------ A revoir ----------------------------------
        // Sauvegarde des images de l'array
        /*for cpt in 0...counterImage-1 {
            UIImageWriteToSavedPhotosAlbum(imageTab[cpt], nil, nil, nil)
        }*/
        //--------------------------------------------------------------------------
        
        
        //let url = URL(string: imagePath[counterImage-2])
        //print("URL before Data : ", url)
        /*let url = URL(string: imagePath[counterImage-2])
        print("url:", url)
        let imageData = try? Data(contentsOf: url!)
        print("ImageData : ", imageData)
        let image = UIImage(data: imageData!)
        print(image)*/
        //imageView.image = image
    }
    
    
    func didShoot(overlayView:CustomOverlayView) {
        var interval: TimeInterval
        if let intervalValue = UserDefaults.standard.string(forKey: "interval") {
            interval = TimeInterval(intervalValue)!
        } else {
            interval = 1
        }
        print("Video interval : ", interval)
        updateCounter()
        timer = Timer.scheduledTimer(timeInterval: interval, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
    }
    
    func updateCounter() {
        imagePicker.takePicture()
        //imageTab.append(imageView.)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        // Get the Document directory path
        let documentDirectorPath:String = paths[0]
        
        // Create a new path for the new images folder
        imagesDirectoryPath = documentDirectorPath + "/ImagePicker"
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
        
        removeImages() // Delete images if exists
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Enregistre nombre de vidéo créées avec l'application
    // Fonction en double avec parameterTimeLapseViewController => à améliorer
    func saveData(value: Int, key: String) {
        let defaults: UserDefaults = UserDefaults.standard

        do {
            try defaults.removeObject(forKey: key)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    // Fonction en double avec parameterTimeLapseViewController => à améliorer (avec key en tableu paramètre et retour avec la valeur créée)
    func getData() -> Int {
        let defaults: UserDefaults = UserDefaults.standard
        let number:Int = defaults.integer(forKey: "videoNumber") // default value 0
        
        return number
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
    
    // Fonction en double avec parameterTimeLapseViewController => à améliorer (avec key en tableu paramètre et retour avec la valeur créée)
    func getVideoName() -> [String] {
        let defaults: UserDefaults = UserDefaults.standard
        var videoName:[String] = []
        if let name = defaults.stringArray(forKey: "videoName") {
            videoName = name
        }
        
        return videoName
    }


}

