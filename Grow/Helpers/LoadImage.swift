//
//  LoadImage.swift
//  Grow
//
//  Created by Swen Rolink on 25/09/2021.
//

import Foundation
import SwiftUI
import FirebaseStorage

class ImageManager{
    
    class func loadImage(for url: String, completion: @escaping (UIImage) -> Void){
        let defaultImage = UIImage(named: "errorLoading") ?? UIImage()

        guard let imageURL = URL(string: url) else {
            completion(defaultImage)
            return
        }
        
        let cache = URLCache.shared
        let request = URLRequest(url: imageURL, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60.0)
        
        if let data = cache.cachedResponse(for: request)?.data {
            print("Cached image")
            completion(UIImage(data: data) ?? defaultImage)
        } else {
            let storage = Storage.storage()
            
            let imageRef = storage.reference(forURL: url)
            
            imageRef.downloadURL(completion: {urlRequest, error in
                if error != nil {
                    completion(defaultImage)
                } else {
                    print("Fresh image")
                    URLSession.shared.dataTask(with: urlRequest!, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                            
                        let request = URLRequest(url: imageURL, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60.0)
                            
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                completion(UIImage(data: data) ?? defaultImage)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(defaultImage)
                            }
                        }
                    }).resume()
                }
            })
        }
    }
}
