//
//  MeasurementOverview.swift
//  Grow
//
//  Created by Swen Rolink on 07/09/2021.
//

import SwiftUI
import Firebase

struct MeasurementOverview: View {
    @EnvironmentObject var userModel: UserDataModel
    @State var showAddNewMeasurement: Bool = false
    @State var searchText = ""
    @State var searching = false

    
    var body: some View{
        NavigationView{
            VStack(alignment: .leading){
                List {
                    ForEach(self.userModel.measurements, id: \.self) { measurement in
                       MeasurementRow(measurement: measurement)
                   }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text("Metingen"))
            .navigationBarItems(trailing: (
                            Button(action: {
                                withAnimation {
                                    self.showAddNewMeasurement.toggle()
                                }
                            }) {
                                Image(systemName: "plus")
                            })
                        )
        .sheet(isPresented: $showAddNewMeasurement) {
            AddExercise(showAddExerciseSheetView: $showAddNewMeasurement)
            }
        }
    }
}

struct MeasurementRow: View{
    
    @State var measurement: BodyMeasurement
    @State var frontImage: UIImage = UIImage(named: "errorLoading")!
    @State var sideImage: UIImage = UIImage(named: "errorLoading")!
    @State var backImage: UIImage = UIImage(named: "errorLoading")!
    
    func loadFrontImage(for url: String){
        let storage = Storage.storage()
        let imageRef = storage.reference(forURL: url)
        let defaultImage: UIImage = UIImage(named: "errorLoading")!

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
            if error != nil {
                frontImage = defaultImage
          } else {
                frontImage = UIImage(data: data!) ?? defaultImage
          }
        }
    }
    
    func loadSideImage(for url: String){
        let storage = Storage.storage()
        let imageRef = storage.reference(forURL: url)
        let defaultImage: UIImage = UIImage(named: "errorLoading")!

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
            if error != nil {
                sideImage = defaultImage
          } else {
                sideImage = UIImage(data: data!) ?? defaultImage
          }
        }
    }
    
    func loadBackImage(for url: String){
        let storage = Storage.storage()
        let imageRef = storage.reference(forURL: url)
        let defaultImage: UIImage = UIImage(named: "errorLoading")!

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        imageRef.getData(maxSize: 1 * 4000 * 4000) { data, error in
            if error != nil {
                backImage = defaultImage
          } else {
                backImage = UIImage(data: data!) ?? defaultImage
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
                    Image(uiImage: frontImage)
                        .resizable()
                        .scaledToFit()
                    
                    Image(uiImage: sideImage)
                        .resizable()
                        .scaledToFit()
                    
                    Image(uiImage: backImage)
                        .resizable()
                        .scaledToFit()
                }
            }.onAppear(perform: {
                if measurement.frontImageUrl != "" {
                    loadFrontImage(for: measurement.frontImageUrl)
                }
                if measurement.sideImageUrl != "" {
                    loadSideImage(for: measurement.sideImageUrl)
                }
                if measurement.backImageUrl != "" {
                    loadBackImage(for: measurement.backImageUrl)
                }
            })
    }
}

struct MeasurementOverview_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementOverview()
    }
}
