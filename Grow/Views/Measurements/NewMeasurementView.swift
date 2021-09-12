//
//  NewMeasurementView.swift
//  Grow
//
//  Created by Swen Rolink on 04/09/2021.
//

import SwiftUI
import KeyboardToolbar

struct NewMeasurementView: View {
    
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
    @State var uploadedItems:Int = 0
    
    let frontImage: UIImage = UIImage(systemName: "plus")!
    
    let toolbarItems: [KeyboardToolbarItem] = [.dismissKeyboard]
    
    func loadFrontImage() {
        guard inputFrontImage != nil else { return }
    }
    func loadSideImage() {
        guard inputSideImage != nil else { return }
    }
    func loadBackImage() {
        guard inputBackImage != nil else { return }
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
            
        ProgressIndicator(isShowing: $showLoadingIndicator, loadingText: "Meting opslaan", content:{
            
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
        }.onReceive(self.userModel.$uploadedImages, perform: {count in
            if count == 3 {
                self.userModel.saveBodyMeasurement()
                self.showLoadingIndicator = false
                self.userModel.uploadedImages = 0
                self.showMeasurementView = false
            }
        })
        .navigationTitle(Text("Nieuwe meting"))
        
        .navigationBarItems(trailing: Button("Opslaan"){
            
            self.showLoadingIndicator = true
            
            self.userModel.addNewMeasurementPictures(images: inputFrontImage!, name: "Front")
            self.userModel.addNewMeasurementPictures(images: inputSideImage!, name: "Side")
            self.userModel.addNewMeasurementPictures(images: inputBackImage!, name: "Back")
        
        }.disabled(self.inputFrontImage == nil || self.inputSideImage == nil || self.inputBackImage == nil || self.weightInput == ""))
        
        .keyboardToolbar(toolbarItems)
        
        .onTapGesture {
            hideKeyboard()
        }
        
        .sheet(isPresented: $showFrontImagePicker, onDismiss: loadFrontImage) {
            ImagePicker(image: self.$inputFrontImage)
        }
        .sheet(isPresented: $showSideImagePicker, onDismiss: loadSideImage) {
            ImagePicker(image: self.$inputSideImage)
        }
        .sheet(isPresented: $showBackImagePicker, onDismiss: loadBackImage) {
            ImagePicker(image: self.$inputBackImage)
        }
        })
        }
    }
}
