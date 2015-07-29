//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Paul Miller on 22/07/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if imageView.image == nil {
            
            activityIndicatorView.startAnimating()
        }
    }
}
