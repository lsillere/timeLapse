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
private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
private let itemsPerRow: CGFloat = 3

class VideoListCollectionViewController: UICollectionViewController {
    
    var directoryContents = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        directoryContents = getVideoUrl()
        
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
            let thumbnailUiImage = UIImage(cgImage: thumbnailCgImage)

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
        
        let player = AVPlayer(url: directoryContents[indexPath.row])
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }

        return true
    }

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

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

}

extension VideoListCollectionViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
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
