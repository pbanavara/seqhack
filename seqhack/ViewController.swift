//
//  ViewController.swift
//  seqhack
//
//  Created by Pradeep Banavara on 20/09/14.
//  Copyright (c) 2014 Pradeep Banavara. All rights reserved.
//

import UIKit
import MobileCoreServices
import GPUImage
import CoreLocation
import MapKit


class ViewController:  UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    var beenHereBefore = false
    var controller: UIImagePickerController?
    var locationManager: CLLocationManager?
    var locationFixAchieved : Bool = false
    var locationStatus : NSString = "Not Started"
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if beenHereBefore{
            /* Only display the picker once as the viewDidAppear: method gets
            called whenever the view of our view controller gets displayed */
            return;
        } else {
            beenHereBefore = true
        }
        
        if isCameraAvailable() && doesCameraSupportTakingPhotos(){
            
            controller = UIImagePickerController()
            
            if let theController = controller{
                theController.sourceType = .Camera
                
                theController.mediaTypes = [kUTTypeImage as NSString]
                
                theController.allowsEditing = true
                theController.delegate = self
                
                presentViewController(theController, animated: true, completion: nil)
            }
            
        } else {
            println("Camera is not available")
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController!,
        didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!){
            
            println("Picker returned successfully")
            
            let mediaType:AnyObject? = info[UIImagePickerControllerMediaType]
            
            if let type:AnyObject = mediaType{
                
                if type is String{
                    let stringType = type as String
                    
                    if stringType == kUTTypeMovie as NSString{
                        let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL
                        if let url = urlOfVideo{
                            println("Video URL = \(url)")
                        }
                    }
                        
                    else if stringType == kUTTypeImage as NSString as NSString{
                        /* Let's get the metadata. This is only for images. Not videos */
                        let metadata = info[UIImagePickerControllerMediaMetadata]
                            as? NSDictionary
                        if let theMetaData = metadata{
                            let image = info[UIImagePickerControllerOriginalImage]
                                as? UIImage
                            if let theImage = image{
                                var newImage = processImageFilter(theImage)
                                println("Image = \(theImage)")
                                createLocationManager(startImmediately: true)
                                
                            }
                        }
                    }
                    
                }
            }
            picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        println("Picker was cancelled")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func isCameraAvailable() -> Bool{
        return UIImagePickerController.isSourceTypeAvailable(.Camera)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Camera is ")
        if isCameraAvailable() == false{
            print("not ")
        }
        println("available")
        if doesCameraSupportTakingPhotos(){
            println("The camera supports taking photos")
        } else {
            println("The camera does not support taking photos")
        }
        
        if doesCameraSupportShootingVideos(){
            println("The camera supports shooting videos")
        } else {
            println("The camera does not support shooting videos")
        }
        
        
    }
    
    func uploadJson(jsonString: String) {
        var request = NSMutableURLRequest(URL: NSURL(string: "http://projects.vkb.me:3000/actions"), cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        var response: NSURLResponse?
        var error: NSError?
        
        // create some JSON data and configure the request
        
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // send the request
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
        
        // look at the response
        if let httpResponse = response as? NSHTTPURLResponse {
            println("HTTP response: \(httpResponse.statusCode)")
        } else {
            println("No HTTP response")
        }
    }
    
    func cameraSupportsMedia(mediaType: String,
        sourceType: UIImagePickerControllerSourceType) -> Bool{
            let availableMediaTypes =
            UIImagePickerController.availableMediaTypesForSourceType(sourceType)
                as [String]
            for type in availableMediaTypes{
                if type == mediaType{
                    return true
                }
            }
            
            return false
    }
    
    func doesCameraSupportShootingVideos() -> Bool{
        return cameraSupportsMedia(kUTTypeMovie as NSString, sourceType: .Camera)
    }
    
    func doesCameraSupportTakingPhotos() -> Bool{
        return cameraSupportsMedia(kUTTypeImage as NSString, sourceType: .Camera)
    }
    
    // Image processing using GPUImage
    
    func processImageFilter(image :UIImage) -> UIImage{
        var imagePicture = GPUImagePicture(image: image)
        var cannyEdgeFilter = GPUImageCannyEdgeDetectionFilter()
        imagePicture.addTarget(cannyEdgeFilter)
        cannyEdgeFilter.useNextFrameForImageCapture()
        imagePicture.processImage()
        var outputImage = cannyEdgeFilter.imageFromCurrentFramebuffer()
        return outputImage
    }
    
    //Get the lat long of the pothole and transmit the same
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
    
    print("The authorization status of location services is changed to: ")
    
    switch CLLocationManager.authorizationStatus(){
        case .Authorized:
            println("Authorized")
        case .AuthorizedWhenInUse:
            println("Authorized when in use")
        case .Denied:
            println("Denied")
        case .NotDetermined:
            println("Not determined")
        case .Restricted:
            println("Restricted")
        default:
            println("Unhandled")
    }
    
    }
    
    func locationManager(manager: CLLocationManager!,
        didFailWithError error: NSError!){
            println("Location manager failed with error = \(error)")
    }
    
    func displayAlertWithTitle(title: String, message: String){
        let controller = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "OK",
            style: .Default,
            handler: nil))
        presentViewController(controller, animated: true, completion: nil)
        
    }
    
    func createLocationManager(#startImmediately: Bool){
        locationManager = CLLocationManager()
        if let manager = locationManager{
            println("Successfully created the location manager")
            manager.delegate = self
            manager.requestAlwaysAuthorization()
            if startImmediately{
                manager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            var locationArray = locations as NSArray
            var locationObj = locationArray.lastObject as CLLocation
            var coord = locationObj.coordinate
            
            let strLat = NSString(format:"%.9f", coord.latitude)
            let strLng = NSString(format:"%.9f", coord.longitude)
            
            println(coord.latitude)
            println(coord.longitude)
            var jsonString = "{\"user\":\"541e03418cdaa72e1fbbc78e\",\"action\":\"DETECT\",\"condition\":\"POTHOLE\", \"coordinates\": { \"location\" : { \"lat\" :" + strLat + ", \"lng\" :" + strLng + "}}}"
            println(jsonString)
            uploadJson(jsonString)
            manager.stopUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

