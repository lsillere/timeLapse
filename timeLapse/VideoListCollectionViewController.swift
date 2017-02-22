//
//  VideoListViewControllerCollectionViewController.swift
//  timeLapse
//
//  Created by Loic Sillere on 05/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

private let reuseIdentifier = "VideoCell"
private let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 50.0, right: 5.0)
private let itemsPerRow: CGFloat = 3

class VideoListCollectionViewController: UICollectionViewController {
    
    var directoryContents = [URL]()
    var cellSize: Int = 0
    var selectedPhotos = [URL]()
    var edit:Bool = false
    
    @IBOutlet var videoCollectionView: UICollectionView!
    @IBOutlet weak var deleteBarButtonItem: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        directoryContents = getVideoUrl()
        videoCollectionView?.allowsMultipleSelection = true
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: 375 / 3, height: 375 / 3)
        videoCollectionView!.collectionViewLayout = layout

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(VideoCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editBarButton(_ sender: UIBarButtonItem) {
        if(edit == false) {
            edit = true
            print("edit")
            deleteBarButtonItem.isEnabled = true
        } else {
            edit = false
            if !selectedPhotos.isEmpty {
                selectedPhotos = [URL]()
                print("remove selected photo")
                deselectAllvideo()
            }
            print("cancel")
        }
    }

    @IBAction func deleteBarButton(_ sender: UIBarButtonItem) {
        if !selectedPhotos.isEmpty {
            print("delete")
            edit = false
            
            // Delete video
            for video in selectedPhotos {
                removeVideoIfExist(videoOutputURL: video)
            }
            
            // Clear seletVideoo list
            selectedPhotos = [URL]()

            deselectAllvideo()
            deleteBarButtonItem.isEnabled = false
            
            directoryContents = getVideoUrl()
            collectionView?.reloadData()
        }
    }
    
    func getVideoUrl() -> [URL] {
        var  directoryContents = [URL]()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("/TimeLapseVideo"))
        
        // Show existing video thumbnail
        do {
            // Get the directory contents urls of time lapse videos (including subfolders urls)
            directoryContents = try FileManager.default.contentsOfDirectory(at: videoOutputURL, includingPropertiesForKeys: nil, options: [])
            
            //if(directoryContents.isEmpty) { // No video in folder -> print message
            //self.noVideoMessage.text = "Aucune video"
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        print("directory contents: ", directoryContents)
        return directoryContents
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return directoryContents.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! VideoCell
        cell.backgroundColor = UIColor.white
        
        let asset = AVURLAsset(url: directoryContents[indexPath.row], options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let thumbnailCgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnailUiImage = cropImage(image: UIImage(cgImage: thumbnailCgImage), size: cellSize)
            cell.imageViewCell.image = thumbnailUiImage
        } catch let error as NSError {
            print(error.localizedDescription)
        }

        return cell
    }
    

    // MARK: UICollectionViewDelegate

    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        print(indexPath)
        if(edit == false) {
            let player = AVPlayer(url: directoryContents[indexPath.row])
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
            print("test shouldHighlightItemAt")
        }
        
        return true
    }

    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if(edit == true) {
            print(selectedPhotos)
            
            return true
        } else {
            return false
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        if(edit == true) {
            selectedPhotos.append(directoryContents[indexPath.row])
            
            print(selectedPhotos)
            print("select")
        }
    }
 
    override func collectionView(_ collectionView: UICollectionView,
                                 didDeselectItemAt indexPath: IndexPath) {
        if(edit == true) {
            if let indexOfvideo = selectedPhotos.index(of: directoryContents[indexPath.row]) {
                selectedPhotos.remove(at: indexOfvideo)
            }
            
            print(selectedPhotos)
            print("deselect")
        }
    }
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    func cropImage(image: UIImage, size: Int) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(size)
        var cgheight: CGFloat = CGFloat(size)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    func deselectAllvideo() {
        for indexPath in videoCollectionView.indexPathsForSelectedItems! {
            videoCollectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    func removeVideoIfExist(videoOutputURL: URL) {
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch let writerError as NSError {
            print(writerError)
        }
    }
}

extension VideoListCollectionViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        cellSize = Int(widthPerItem)
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
