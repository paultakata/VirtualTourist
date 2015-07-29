//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Paul Miller on 15/07/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    //MARK: - Properties
    
    @NSManaged var photoURL:      String
    @NSManaged var imageFilePath: String?
    @NSManaged var pin:           Pin
    
    var image: UIImage? {
        
        if let imageFilePath = imageFilePath {
            
            //Here I use "error" to denote if there was an error in pre-downloading the image.
            //Also see getImageForPhoto(photo:, completionHandler:) in VirtualTouristConvenience.
            if imageFilePath == "error" {
                
                return UIImage(named: "sadkittyerror.jpg")
            }
            
            //After far too long I found the sandbox path can (and does) change. Grrr.😠
            //So I reassemble the filePath here.
            let fileName = imageFilePath.lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }

    //MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoURL = photoURL
        self.pin = pin
    }
    
    //MARK: - Overrides
    
    override func prepareForDeletion() {
        
        //Delete the associated image file when the Photo managed object is deleted.
        if let fileName = imageFilePath?.lastPathComponent {
            
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, fileName]
        let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
        
        NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
        }
    }
}
