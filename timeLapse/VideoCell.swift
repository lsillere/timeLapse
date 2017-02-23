//
//  VideoCell.swift
//  timeLapse
//
//  Created by Loic Sillere on 05/02/2017.
//  Copyright © 2017 Loic Sillere. All rights reserved.
//

import UIKit

class VideoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageViewCell: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            imageViewCell.layer.borderWidth = isSelected ? 4 : 0
            imageViewCell.alpha = isSelected ? 0.6 : 1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageViewCell.layer.borderColor = UIColor(red: 151/255, green: 198/255, blue: 177/255, alpha: 1).cgColor
        isSelected = false
    }
}
