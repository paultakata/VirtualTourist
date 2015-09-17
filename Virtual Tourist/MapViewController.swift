//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Paul Miller on 15/07/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class MapViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var mapView          : MKMapView!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var tapPinsLabel     : UILabel!
    @IBOutlet var longPressRecognizer   : UILongPressGestureRecognizer!
    
    var inEditingMode        = false
    var lastPinDropped: Pin? = nil
    var pinToBeAdded  : Pin? = nil
    
    //MARK: Constants
    
    let CentreLatitudeKey     = "Centre Latitude Key"
    let CentreLongitudeKey    = "Centre Longitude Key"
    let SpanLatitudeDeltaKey  = "Span Latitude Delta Key"
    let SpanLongitudeDeltaKey = "Span Longitude Delta Key"
    
    // MARK: Core Data convenience
    
    var sharedContext: NSManagedObjectContext {
        
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }
    
    //MARK: - View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //Set delegates.
        mapView.delegate = self
        
        //Add existing pins to mapView.
        mapView.addAnnotations(fetchAllPins())
        
        //Attempt to reshow the last map region.
        loadMapRegion()
    }

    //MARK: - Memory management
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - IBAction methods
    
    @IBAction func longPressGestureTriggered(sender: UILongPressGestureRecognizer) {
        
        //Get coordinate of the point the user touched on the mapView...
        let pointTouched = sender.locationInView(mapView)
        let location = mapView.convertPoint(pointTouched, toCoordinateFromView: mapView)
        
        switch sender.state {
            
            //...and use it to initialise a new Pin managed object. Store it for reuse.
        case .Began:
            pinToBeAdded = Pin(coordinate: location, context: sharedContext)
            mapView.addAnnotation(pinToBeAdded!)
        
            //If the user drags the pin around, use KVO to update the location of the pin
            //and the coordinate property of the Pin object.
        case .Changed:
            pinToBeAdded!.willChangeValueForKey("coordinate")
            pinToBeAdded!.coordinate = location
            pinToBeAdded!.didChangeValueForKey("coordinate")
            
            //When the user drops the pin, store it for error handling, fetch the associated
            //photos and finally save it to Core Data.
        case .Ended:
            lastPinDropped = pinToBeAdded
            fetchPhotosForPin(pinToBeAdded!)
            CoreDataStackManager.sharedInstance.saveContext()
            
        default:
            return
        }
    }

    @IBAction func editButtonPressed(sender: UIBarButtonItem) {
        
        if inEditingMode {
            
            //Return the view to normal.
            editBarButtonItem.title = "Edit"
            
            UIView.animateWithDuration(0.6,
                delay: 0,
                options: [.BeginFromCurrentState, .CurveEaseInOut],
                animations: { self.tapPinsLabel.alpha = 0.0 },
                completion: nil)

            inEditingMode = false
        } else {
            
            //Change the view to show editing label and "Done" button.
            inEditingMode = true
            
            UIView.animateWithDuration(0.6,
                delay: 0,
                options: [.Autoreverse, .CurveEaseInOut, .Repeat],
                animations: { self.tapPinsLabel.alpha = 1.0 },
                completion: nil)
            
            editBarButtonItem.title = "Done"
        }
    }
    
    //MARK: - Helper functions
    
    func fetchAllPins() -> [Pin] {
        
        let error: NSErrorPointer = nil
        
        //Create and execute the fetch request.
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let results: [AnyObject]?
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }
        
        //Check for errors
        if error != nil {
            
            alertUserWithTitle("Error",
                message: "Something weird happened. If it keeps happening you might have to reinstall.",
                retry: false)
        }
        
        return results as! [Pin]
    }
    
    func fetchPhotosForPin(pin: Pin) {
        
        VirtualTouristClient.sharedInstance.getPhotosForPin(pin, completionHandler: {
            success, error in
            
            if success {
                
                //Save the new Photo objects to Core Data.
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance.saveContext()
                })
            } else {
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.alertUserWithTitle("Error",
                        message: "There was a problem downloading your pictures.",
                        retry: true)
                })
            }
        })
    }
    
    func saveMapRegion() {
        
        //The mapView region property is a struct containing 4 double values.
        //This saves each value individually to NSUserDefaults.
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: CentreLatitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: CentreLongitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: SpanLatitudeDeltaKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: SpanLongitudeDeltaKey)
    }
    
    func loadMapRegion() {
        
        //Check for user defaults, if they exist then zoom map to old location.
        //Check for existence of centreLatitude before proceeding. doubleForKey() returns 0 if key doesn't exist.
        let centreLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(CentreLatitudeKey)
        
        if centreLatitude != 0 {
            
            //Assemble all the things...
            let centreLongitude    = NSUserDefaults.standardUserDefaults().doubleForKey(CentreLongitudeKey)
            let spanLatitudeDelta  = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLatitudeDeltaKey)
            let spanLongitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLongitudeDeltaKey)
            
            let centre = CLLocationCoordinate2DMake(centreLatitude, centreLongitude)
            let span = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
            
            //...into a region...
            let region = MKCoordinateRegionMake(centre, span)
            
            //...and move the map back to where the user left it.
            mapView.region = region
        }
    }
    
    func alertUserWithTitle(title: String, message: String, retry: Bool) {
        
        //Create alert and show it to user.
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        
        if retry {
            
            let retryAction = UIAlertAction(title: "Retry",
                style: .Destructive,
                handler: {
                    action in
                    
                    self.fetchPhotosForPin(self.lastPinDropped!)
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

//MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if inEditingMode {
            
            //Get the Pin...
            let pin = view.annotation as! Pin
            
            //...remove it from the mapView...
            mapView.removeAnnotation(pin)
            
            //...delete it and save the context.
            sharedContext.deleteObject(pin)
            CoreDataStackManager.sharedInstance.saveContext()
        } else {
            
            //Get the next view controller and the pin to pass it...
            let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoCollectionViewController") as! PhotoCollectionViewController
            let pin = view.annotation as! Pin
            
            //...assign the pin...
            nextVC.receivedPin = pin
            
            //...and segue to it.
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        //Use dequeued pin annotation view if available, otherwise create a new one.
        if let annotation = annotation as? Pin {
            
            let identifier = "Pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                view.animatesDrop = true
                view.draggable = false
            }
            
            return view
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        //Save the map region as the user moves it around.
        saveMapRegion()
    }
}
