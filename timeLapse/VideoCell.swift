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
            imageViewCell.layer.borderWidth = isSelected ? 2 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageViewCell.layer.borderColor = UIColor.blue.cgColor
        isSelected = false
    }
}
