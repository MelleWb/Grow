//
//  LoadImage.swift
//  Grow
//
//  Created by Swen Rolink on 25/09/2021.
//

import Foundation
import SwiftUI
import Firebase

class ImageManager{
    
    class func loadImage(for url: String, completion: @escaping (UIImage) -> Void){
        
        let cache = URLCache.shared
        let request = URLRequest(url: URL(string: url)!, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60.0)
        
        if let data = cache.cachedResponse(for: request)?.data {
            print("Cached image")
            completion(UIImage(data: data)!)
        } else {
            let storage = Storage.storage()
            
            let imageRef = storage.reference(forURL: url)
            let defaultImage: UIImage = UIImage(named: "errorLoading")!
            
            imageRef.downloadURL(completion: {urlRequest, error in
                if error != nil {
                    completion(defaultImage)
                } else {
                    print("Fresh image")
                    URLSession.shared.dataTask(with: urlRequest!, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                            
                        let request = URLRequest(url: URL(string: url)!, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60.0)
                            
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                completion(UIImage(data: data)!)
                            }
                        }
                    }).resume()
                }
            })
        }
    }
}
