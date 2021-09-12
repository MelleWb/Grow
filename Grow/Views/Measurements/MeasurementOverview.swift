//
//  MeasurementOverview.swift
//  Grow
//
//  Created by Swen Rolink on 07/09/2021.
//

import SwiftUI
import Firebase
import ImageViewer
import Introspect

struct MeasurementOverview: View {
    @EnvironmentObject var userModel: UserDataModel
    @State var showAddNewMeasurement: Bool = false
    @State var showCompareMeasurement: Bool = false
    
    @State var imageForViewer = Image("errorLoading")
    @State var showImageViewer: Bool = false
    @State var compare: Bool = false
    @State var selectedMeasurements: [BodyMeasurement]? = nil
    
    func shouldBeDisabled()->Bool{
        if compare {
            if self.selectedMeasurements?.count == 2 {
                return false
            }
            else {
                return true
            }
        } else {
            return false
        }
    }

    var body: some View{
        NavigationView{
            VStack(alignment: .leading){
                if showAddNewMeasurement{
                    NavigationLink(destination: NewMeasurementView(showMeasurementView: $showAddNewMeasurement),isActive: self.$showAddNewMeasurement){
                        NewMeasurementView(showMeasurementView: $showAddNewMeasurement)
                    }.hidden()
                }
                if showCompareMeasurement{
                    NavigationLink(destination: CompareMeasurements(selectedMeasurements:$selectedMeasurements, imageForViewer: $imageForViewer, showImageViewer: $showImageViewer),isActive: self.$showCompareMeasurement){
                        CompareMeasurements(selectedMeasurements: $selectedMeasurements, imageForViewer: $imageForViewer, showImageViewer: $showImageViewer)
                    }.hidden()
                }
                ScrollView{
                    ForEach(self.userModel.measurements, id: \.self) { measurement in
                        MeasurementRow(measurement: measurement, imageForViewer: $imageForViewer, showImageViewer: $showImageViewer, compare: $compare, selectedMeasurements: $selectedMeasurements)
                   }
                }
            }
            .navigationTitle(Text("Metingen"))
            .navigationBarItems(leading: (
                Button(action: {
                    withAnimation {
                        if compare {
                            self.compare.toggle()
                        } else {
                        self.showAddNewMeasurement.toggle()
                        }
                    }
                    }) {
                    if compare{
                        Text("Annuleer")
                    } else {
                        Image(systemName: "plus")
                    }
                    }
                    ),
                trailing: (
                    Button(action: {
                        withAnimation {
                            if compare {
                                self.showCompareMeasurement.toggle()
                                
                            } else {
                            self.compare.toggle()
                            }
                        }
                    }) {
                        if compare{
                            Text("Vergelijk")
                        } else {
                            Text("Selecteer")
                        }
                    }.disabled(shouldBeDisabled())
                )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(ImageViewer(image: self.$imageForViewer, viewerShown: self.$showImageViewer, closeButtonTopRight: true))
    }
}

struct MeasurementRow: View{
    
    @State var measurement: BodyMeasurement
    @State var frontImage: UIImage = UIImage(named: "TorsoFront")!
    @State var sideImage: UIImage = UIImage(named: "TorsoSide")!
    @State var backImage: UIImage = UIImage(named: "TorsoBack")!
    
    @Binding var imageForViewer: Image
    @Binding var showImageViewer: Bool
    @Binding var compare : Bool
    @Binding var selectedMeasurements: [BodyMeasurement]?
    
    func loadImage(for url: String, completion: @escaping (UIImage) -> Void){
        let storage = Storage.storage()
        let imageRef = storage.reference(forURL: url)
        let defaultImage: UIImage = UIImage(named: "errorLoading")!

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
    
    var body: some View{
        VStack(alignment:.leading){
            HStack{
                Text(measurement.date, style: .date)
                    .font(.headline)
                    .padding()
                Spacer()
                Text("\(NumberHelper.roundedNumbersFromDouble(unit: measurement.weight ?? 0)) kg")
                    .padding()
            }
                HStack{
                    if compare {
                        HStack{
                            Button(action:{
                                if self.selectedMeasurements == nil {
                                    self.selectedMeasurements = [measurement]
                                }
                                else {
                                    let index = selectedMeasurements!.firstIndex(where: { $0.documentID == measurement.documentID})
                                    if index == nil {
                                        //Add to the selectedMeasurements
                                        if self.selectedMeasurements!.count <= 1 {
                                            self.selectedMeasurements?.append(measurement)
                                        }
                                    }
                                    else{
                                        //Remove from the selectedMeasurements
                                        self.selectedMeasurements?.remove(at: index ?? 0)
                                    }
                                }
                            }, label:{
                                
                                if selectedMeasurements != nil {
                                    
                                    let index = selectedMeasurements!.firstIndex(where: { $0.documentID == measurement.documentID})
                                    
                                    if index != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .padding()
                                        .frame(width: 75, height: 75)
                                    }
                                    else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.accentColor)
                                            .padding()
                                            .frame(width: 75, height: 75)
                                    }
                                }
                                else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.accentColor)
                                        .padding()
                                        .frame(width: 75, height: 75)
                                }
                            
                            })
                        }
                    }
                    Button(action: {
                        self.imageForViewer = Image(uiImage: frontImage)
                        self.showImageViewer = true
                    }, label:{
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFit()
                    }).shadow(radius: 5)
                    
                    Button(action: {
                        self.imageForViewer = Image(uiImage: sideImage)
                        self.showImageViewer = true
                    }, label:{
                        Image(uiImage: sideImage)
                            .resizable()
                            .scaledToFit()
                    }).shadow(radius: 5)
                    
                    Button(action: {
                        self.imageForViewer = Image(uiImage: backImage)
                        self.showImageViewer = true
                    }, label:{
                        Image(uiImage: backImage)
                            .resizable()
                            .scaledToFit()
                    }).shadow(radius: 5)
                }.padding()
            Divider()
        }
        
        .onAppear(perform: {
                if measurement.frontImageUrl != "" {
                    loadImage(for: measurement.frontImageUrl, completion: {image in
                        self.frontImage = image
                    })
                }
                if measurement.sideImageUrl != "" {
                    loadImage(for: measurement.sideImageUrl, completion: {image in
                        self.sideImage = image
                    })
                }
                if measurement.backImageUrl != "" {
                    loadImage(for: measurement.backImageUrl, completion: {image in
                        self.backImage = image
                    })
                }
            })
    }
}

struct MeasurementOverview_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementOverview()
    }
}
