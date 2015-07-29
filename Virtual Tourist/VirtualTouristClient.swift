//
//  VirtualTouristClient.swift
//  Virtual Tourist
//
//  Created by Paul Miller on 20/07/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation

class VirtualTouristClient {
    
    //MARK: - Shared Instance
    
    //Single line shared instance declaration. Still thread safe!😄
    //Via http://krakendev.io/blog/the-right-way-to-write-a-singleton
    
    static let sharedInstance = VirtualTouristClient()
    
    //MARK: - Properties
    
    var session: NSURLSession
    
    //MARK: - Initialiser
    
    private init() { //Ensures others can't create another VirtualTouristClient using the default "()" initialiser.
        
        session = NSURLSession.sharedSession()
    }
    
    //MARK: - GET
    
    func GETMethod(parameters: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            //Build the URL and URL request specific to the website required.
            let urlString = Constants.BaseFlickrURL + VirtualTouristClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //Parse the received data.
                if let error = downloadError {
                    
                    let newError = VirtualTouristClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    VirtualTouristClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    func GETMethodForURLString(urlString: String,
        completionHandler: (result: NSData?, error: NSError?) -> Void) {
            
            //Create request with urlString.
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                if let error = downloadError {
                    
                    let newError = VirtualTouristClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    completionHandler(result: data, error: nil)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    //MARK: - Helper functions.
    
    //I repurposed these from Jarrod's code in The Movie Manager, so they are similar.
    
    //Reformat parameters to be usable in URLs.
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range: nil)
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    //Check to see if there is a received error, if not, return the original local error.
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments, error: nil) as? [String : AnyObject] {
            
            if let status = parsedResult[JSONResponseKeys.Status]  as? String,
                  message = parsedResult[JSONResponseKeys.Message] as? String {
                    
                if status == JSONResponseValues.Failure {
                    
                    let userInfo = [NSLocalizedDescriptionKey: message]
                    
                    return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
                }
            }
        }
        return error
    }

    //Parse the received JSON data and pass it to the completion handler.
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            
            completionHandler(result: nil, error: error)
        } else {
            
            completionHandler(result: parsedResult, error: nil)
        }
    }
}