//
//  CompareMeasurements.swift
//  Grow
//
//  Created by Swen Rolink on 10/09/2021.
//

import SwiftUI
import Firebase
import ImageViewer

struct CompareMeasurements: View {
    @Binding var selectedMeasurements: [BodyMeasurement]?
    
    @Binding var imageForViewer: Image
    @Binding var showImageViewer: Bool
    
    @State var oldFrontImage: UIImage = UIImage(named: "TorsoFront")!
    @State var oldSideImage: UIImage = UIImage(named: "TorsoSide")!
    @State var oldBackImage: UIImage = UIImage(named: "TorsoBack")!
    
    @State var newFrontImage: UIImage = UIImage(named: "TorsoFront")!
    @State var newSideImage: UIImage = UIImage(named: "TorsoSide")!
    @State var newBackImage: UIImage = UIImage(named: "TorsoBack")!


    func loadImage(for url: String, completion: @escaping (UIImage?) -> Void){
        let storage = Storage.storage()
        let imageRef = storage.reference(forURL: url)
        let defaultImage: UIImage = UIImage(named: "TorsoFront")!

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
            if error != nil {
                completion(defaultImage)
          } else {
            if let image = UIImage(data: data!){
                completion(image)
            } else {
                completion(defaultImage)
            }
          }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView{
                VStack{
                    
                    Button(action: {
                        let mergedImage: UIImage = oldFrontImage.mergedSideBySide(with: newFrontImage)!
                        self.imageForViewer =  Image(uiImage: mergedImage)
                        self.showImageViewer = true
                    }, label:{
                        HStack{
                            
                            Image(uiImage: oldFrontImage)
                                .resizable()
                                .scaledToFit()
                                
                            
                            Image(uiImage: newFrontImage)
                                .resizable()
                                .scaledToFit()
                            
                        }
                    }).shadow(radius: 5)

                        
                    Button(action: {
                        let mergedImage: UIImage = oldSideImage.mergedSideBySide(with: newSideImage)!
                        self.imageForViewer =  Image(uiImage: mergedImage)
                        self.showImageViewer = true
                    }, label:{
                        HStack{
                            
                            Image(uiImage: oldSideImage)
                                .resizable()
                                .scaledToFit()
                                
                            
                            Image(uiImage: newSideImage)
                                .resizable()
                                .scaledToFit()
                            
                        }
                    }).shadow(radius: 5)
                    
                    Button(action: {
                        let mergedImage: UIImage = oldBackImage.mergedSideBySide(with: newBackImage)!
                        self.imageForViewer =  Image(uiImage: mergedImage)
                        self.showImageViewer = true
                    }, label:{
                        HStack{
                            
                            Image(uiImage: oldBackImage)
                                .resizable()
                                .scaledToFit()
                                
                            
                            Image(uiImage: newBackImage)
                                .resizable()
                                .scaledToFit()
                            
                        }
                    }).shadow(radius: 5)
                }
            }
        }.onAppear(perform:{
            
            // First sort from oldest to newest
            self.selectedMeasurements?.sort(by: {$0.date < $1.date})
            
            // get old photos
            if self.selectedMeasurements![0].frontImageUrl != "" {
                loadImage(for: self.selectedMeasurements![0].frontImageUrl, completion: {image in
                    self.oldFrontImage = image!
                })
            }
            if self.selectedMeasurements![0].sideImageUrl != "" {
                loadImage(for: self.selectedMeasurements![0].sideImageUrl, completion: {image in
                    self.oldSideImage = image!
                })
            }
            if self.selectedMeasurements![0].backImageUrl != "" {
                loadImage(for: self.selectedMeasurements![0].backImageUrl, completion: {image in
                    self.oldBackImage = image!
                })
            }
            
            //Get new photos
            
            if self.selectedMeasurements![1].frontImageUrl != "" {
                loadImage(for: self.selectedMeasurements![1].frontImageUrl, completion: {image in
                    self.newFrontImage = image!
                })
            }
            if self.selectedMeasurements![1].sideImageUrl != "" {
                loadImage(for: self.selectedMeasurements![1].sideImageUrl, completion: {image in
                    self.newSideImage = image!
                })
            }
            if self.selectedMeasurements![1].backImageUrl != "" {
                loadImage(for: self.selectedMeasurements![1].backImageUrl, completion: {image in
                    self.newBackImage = image!
                })
            }
        })
    }
}

extension UIImage {
    
    func mergedSideBySide(with otherImage: UIImage) -> UIImage? {

        let mergedWidth = self.size.width + otherImage.size.width
        let mergedHeight = max(self.size.height, otherImage.size.height)
        let mergedSize = CGSize(width: mergedWidth, height: mergedHeight)
        
        UIGraphicsBeginImageContext(mergedSize)
        
        self.draw(in: CGRect(x: 0, y: 0, width: mergedWidth/2, height: mergedHeight))
        
        otherImage.draw(in: CGRect(x: self.size.width, y: 0, width: mergedWidth/2, height: mergedHeight))
        
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return mergedImage
      }
}
