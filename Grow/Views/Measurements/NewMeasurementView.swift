//
//  NewMeasurementView.swift
//  Grow
//
//  Created by Swen Rolink on 04/09/2021.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct NewMeasurementView: View {
    
    //@FocusState private var textFieldIsFocused: Bool
    
    @EnvironmentObject var userModel: UserDataModel
    
    @State private var showFrontImagePicker = false
    @State private var showSideImagePicker = false
    @State private var showBackImagePicker = false
    
    @State private var inputFrontImage: UIImage?
    @State private var inputSideImage: UIImage?
    @State private var inputBackImage: UIImage?
    
    @State private var weightInput: String = ""
    
    @Binding var showMeasurementView: Bool
    @State var showLoadingIndicator: Bool = false
    @State var showAlert: Bool = false
    @State var uploadProgress: Double = 0
    @State var uploadedPictures: Int = 0
    
    let frontImage: UIImage = UIImage(systemName: "plus")!
    
    func loadFrontImage() {
        guard inputFrontImage != nil else { return }
    }
    func loadSideImage() {
        guard inputSideImage != nil else { return }
    }
    func loadBackImage() {
        guard inputBackImage != nil else { return }
    }
    
    func addMeasurementPicture(image: UIImage, name: String, width: CGFloat, height: CGFloat, completion: @escaping (Bool, String)-> Void){
        
        let storageRef = Storage.storage().reference().child("\(self.userModel.user.id!) \((UUID()))_\(Date())_\(name)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        metadata.cacheControl = "public,max-age=4000"
        
        let image = userModel.resizeImage(image:image, targetSize: CGSize(width: width, height: height))!
        
        let uploadImage = storageRef.putData(image.pngData()!, metadata: metadata)
        
            uploadImage.observe(.progress) { snapshot in
                self.uploadProgress = 100.0 * Double(snapshot.progress!.completedUnitCount)
                   / Double(snapshot.progress!.totalUnitCount)
            }
            
            uploadImage.observe(.success) { snapshot in
                
                snapshot.reference.downloadURL { url, error in
                        completion(true, url!.absoluteString)
                        }
            }

            uploadImage.observe(.failure) { snapshot in
                if let error = snapshot.error as NSError? {
                    completion(false, error.description)
            }
        }
    }
    
    func uploadFinished() {
        //Update the counter
        uploadedPictures += 1
        
        //Now check if it uploaded 6 images. Only then save the bodymeasurement and close the view
        if uploadedPictures == 6 {
            self.userModel.saveBodyMeasurement()
            self.showLoadingIndicator = false
            self.showMeasurementView = false
        }
    }
    
    var body: some View {
        
        let weightBinding = Binding<String>(
            get: {self.weightInput},
            set: {weight in
                if let value = NumberFormatter().number(from: weight){
                    self.userModel.measurement.weight = value.doubleValue
                }
                self.weightInput = weight
                
            })
        
        let dateBinding = Binding<Date>(
            get: {self.userModel.measurement.date},
            set: {date in
                self.userModel.measurement.date = date
            })
        
        VStack{

        GeometryReader{ geometry in
            List{
                HStack{
                    if inputFrontImage != nil{
                    Image(uiImage: inputFrontImage!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width/3.5)
                        .onTapGesture {
                            self.showFrontImagePicker = true
                            }
                    } else {
                        VStack{
                            Text("Voorkant")
                            Image("TorsoFront")
                                .frame(alignment: .center)
                        }.frame(width: geometry.size.width/3.5)
                        .onTapGesture {
                            self.showFrontImagePicker = true
                        }
                    }
                    if inputSideImage != nil{
                    Image(uiImage: inputSideImage!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width/3.5)
                        .onTapGesture {
                            self.showSideImagePicker = true
                            }
                    } else {
                        VStack{
                            Text("Zijkant")
                            Image("TorsoSide")
                                .frame(alignment: .center)
                        }.frame(width: geometry.size.width/3.5)
                        .onTapGesture {
                            self.showSideImagePicker = true
                        }
                    }
                    if inputBackImage != nil{
                    Image(uiImage: inputBackImage!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width/3.5)
                            .onTapGesture {
                                self.showBackImagePicker = true
                            }
                    } else {
                        VStack{
                            Text("Achterkant")
                            Image("TorsoBack")
                                .frame(alignment: .center)
                        }.frame(width: geometry.size.width/3.5)
                        .onTapGesture {
                            self.showBackImagePicker = true
                        }
                    }
                }
                Section{
                    HStack{
                        TextField("Gewicht", text: weightBinding)
                            .padding()
                            .background(Color.init("textField"))
                            .cornerRadius(5.0)
                            .padding(.bottom, 10)
                            .keyboardType(.decimalPad)
                    }.padding()
                    
                    HStack{
                        DatePicker("Datum van de meting", selection: dateBinding, displayedComponents: .date)
                            .padding()
                    }.padding()
                }
            }.listStyle(PlainListStyle())
        }
        .navigationTitle(Text("Nieuwe meting"))
        
        .navigationBarItems(trailing: Button("Opslaan"){
            
            self.showLoadingIndicator = true
            
            self.addMeasurementPicture(image: inputFrontImage!, name: "SmallFront", width: 256, height: 341) { success, result in
                if success == true {
                    self.userModel.measurement.smallFrontImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
            
            self.addMeasurementPicture(image: inputFrontImage!, name: "LargeFront", width: 768, height: 1024) { success, result in
                if success == true {
                    self.userModel.measurement.largeFrontImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
            
            self.addMeasurementPicture(image: inputSideImage!, name: "SmallSide", width: 256, height: 341) { success, result in
                if success == true {
                    self.userModel.measurement.smallSideImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
            
            self.addMeasurementPicture(image: inputSideImage!, name: "LargeSide", width: 768, height: 1024) { success, result in
                if success == true {
                    self.userModel.measurement.largeSideImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
            
            self.addMeasurementPicture(image: inputBackImage!, name: "SmallBack", width: 256, height: 341) { success, result in
                if success == true {
                    self.userModel.measurement.smallBackImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
            
            self.addMeasurementPicture(image: inputBackImage!, name: "LargeBack", width: 768, height: 1024) { success, result in
                if success == true {
                    self.userModel.measurement.largeBackImageUrl = result
                    uploadFinished()
                } else {
                    self.showLoadingIndicator = false
                    showAlert = true
                }
            }
        
        }.disabled(self.inputFrontImage == nil || self.inputSideImage == nil || self.inputBackImage == nil || self.weightInput == ""))

        .onTapGesture {
            //self.textFieldIsFocused = false
            hideKeyboard()
        }
            
        .blur(radius: self.showLoadingIndicator ? 5 : 0)
        .overlay(
            ProgressView("Loading...")
                .padding()
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(10)
                .shadow(radius: 10)
                .frame(width: 500, height: 250, alignment: .center)
                .opacity(self.showLoadingIndicator ? 1 : 0)
            )
        .disabled(self.showLoadingIndicator)
            
        .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Oops"), message: Text("Er ging iets fout met uploaden"), dismissButton: .default(Text("Ok!")))})
        
        .sheet(isPresented: $showFrontImagePicker, onDismiss: loadFrontImage) {
            ImagePicker(image: self.$inputFrontImage)
        }
        .sheet(isPresented: $showSideImagePicker, onDismiss: loadSideImage) {
            ImagePicker(image: self.$inputSideImage)
        }
        .sheet(isPresented: $showBackImagePicker, onDismiss: loadBackImage) {
            ImagePicker(image: self.$inputBackImage)
        }
        }
    }
}
