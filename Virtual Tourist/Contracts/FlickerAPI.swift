//
//  FlickerAPI.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClient {
    
    var dataController: DataController!
    
    // MARK: Network to get photos from Flickr
    func getPhotos(completionHandler: @escaping (_ success: Bool, _ uRLResultLevel1: [String], _ error: String?) -> Void) {
        let methodParameters = [
            StructConstant.FlickrParameterKeys.Method: StructConstant.FlickrParameterValues.SearchMethod,
            StructConstant.FlickrParameterKeys.APIKey: StructConstant.FlickrParameterValues.APIKey,
            StructConstant.FlickrParameterKeys.BoundingBox: bboxString(),
            StructConstant.FlickrParameterKeys.SafeSearch: StructConstant.FlickrParameterValues.UseSafeSearch,
            StructConstant.FlickrParameterKeys.Extras: StructConstant.FlickrParameterValues.MediumURL,
            StructConstant.FlickrParameterKeys.Format: StructConstant.FlickrParameterValues.ResponseFormat,
            StructConstant.FlickrParameterKeys.NoJSONCallback: StructConstant.FlickrParameterValues.DisableJSONCallback
        ]
        
        getFlickrData(methodParameters as [String:AnyObject]) { (success, uRLResultLevel2, error) in
            if success {
                // Proceed
                let uRLArray = uRLResultLevel2
                completionHandler(true, uRLArray, nil)
            } else {
                performUIUpdatesOnMain {
                    completionHandler(false, [], error)
                }
            }
        }
    }
    
    private func bboxString() -> String {
        // ensure bbox is bounded by minimum and maximums, has max and mins if wanting to add enter in own coordinates feature
        let latitude = UserDefaults.standard.double(forKey: "InitialLatitude")
        let longitude = UserDefaults.standard.double(forKey: "InitialLongitude")
        let minimumLon = max(longitude - StructConstant.Flickr.SearchBBoxHalfWidth, StructConstant.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - StructConstant.Flickr.SearchBBoxHalfHeight, StructConstant.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + StructConstant.Flickr.SearchBBoxHalfWidth, StructConstant.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + StructConstant.Flickr.SearchBBoxHalfHeight, StructConstant.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Flickr API
    
    private func getFlickrData(_ methodParameters: [String: AnyObject], completionHandler: @escaping (_ success: Bool, _ uRLResultLevel2: [String], _ error: String?) -> Void) {
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(false, [], "There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(false, [], "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(false, [], "No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                completionHandler(false, [], "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[StructConstant.FlickrResponseKeys.Status] as? String, stat == StructConstant.FlickrResponseValues.OKStatus else {
                completionHandler(false, [], "Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
                return
            }
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[StructConstant.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(false, [], "Cannot find keys '\(StructConstant.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[StructConstant.FlickrResponseKeys.Pages] as? Int else {
                completionHandler(false, [], "Cannot find key '\(StructConstant.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getRandomPageFlickrData(methodParameters, withPageNumber: randomPage) { (success, uRLResultLevel3, error) in
                if success {
                    // Proceed
                    let uRLArray = uRLResultLevel3
                    completionHandler(true, uRLArray, nil)
                } else {
                    performUIUpdatesOnMain {
                        completionHandler(false, [], error)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func getRandomPageFlickrData(_ methodParameters: [String: AnyObject], withPageNumber: Int, completionHandler: @escaping (_ success: Bool, _ uRLResultLevel3: [String], _ error: String?) -> Void) {
        
        // add the page to the method's parameters as new var
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[StructConstant.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParametersWithPageNumber))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(false, [], "There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandler(false, [], "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandler(false, [], "No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                completionHandler(false, [], "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[StructConstant.FlickrResponseKeys.Status] as? String, stat == StructConstant.FlickrResponseValues.OKStatus else {
                completionHandler(false, [], "Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[StructConstant.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler(false, [], "Cannot find key '\(StructConstant.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[StructConstant.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandler(false, [], "Cannot find key '\(StructConstant.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            /* GUARD: Check if any photos exist */
            guard photosArray.count != 0 else {
                completionHandler(false, [], "No Photos Found. Search Again.")
                return
            }
            
            var randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
            
            // use 21 consecutive image URLs or number available
            if randomPhotoIndex > 21 {
                randomPhotoIndex = (randomPhotoIndex - 21)
            }
            if photosArray.count <= 21 {
                randomPhotoIndex = 0
            }
            let numberOfPhotosToShow = min(photosArray.count, 21)
            
            var photoNumberIndex = 0
            var uRLArray = [String]()
            while photoNumberIndex != numberOfPhotosToShow {
                
                var photoDictionary = photosArray[randomPhotoIndex + photoNumberIndex] as [String: AnyObject]
                
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary[StructConstant.FlickrResponseKeys.MediumURL] as? String else {
                    completionHandler(false, [], "Cannot find key '\(StructConstant.FlickrResponseKeys.MediumURL)' in \(photoDictionary)")
                    return
                }
                
                uRLArray.append(imageUrlString)
                photoNumberIndex += 1
            }
            
            completionHandler(true, uRLArray, nil)
        }
        task.resume()
    }
    
    //                TODO: set images
    //                //var photos = [UIImage]()
    //                let imageURL = URL(string: imageUrlString)
    //                //print("imageURL = \(String(describing: imageURL))")
    //                if let imageData = try? Data(contentsOf: imageURL!) {
    //                    photos.append(UIImage(data: imageData)!)
    //                }
    
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = StructConstant.Flickr.APIScheme
        components.host = StructConstant.Flickr.APIHost
        components.path = StructConstant.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}

//// suggestion from mentor
//class NetworkClient: NSObject {
//
//    // shared session
//    var session = URLSession.shared
//
//    // MARK: Initializers
//
//    override init() {
//        super.init()
//    }
//
//
//    func doLogout(session: String, completion: @escaping (_ data: LogoutResponseModel?, _ error : String?) -> Void) {
//        makeRequest(.doLogout(session: session), type: LogoutResponseModel.self, completion: completion)
//    }
//
//    static let shared = NetworkClient()
//}

////and when you want to use a function in this class, you can do as below
//
//NetworkClient.shared.doLogin(email: email, password: password, completion: { (data, error) in
//.....
//})

// If you do choose to use a singleton it should be a private init so that there can be only one (accessed from .shared)

