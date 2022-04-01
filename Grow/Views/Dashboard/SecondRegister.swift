//
//  SecondLogin.swift
//  Grow
//
//  Created by Melle Wittebrood on 28/02/2022.
//

import SwiftUI

struct SecondRegister: View {
    
    @State var birthDate = Date()
    @State var weight: Int = 75
    @State var height: Int = 170
    @State var enableWeightSheet: Bool = false
    @State var enableHeightSheet: Bool = false
    @EnvironmentObject var userModel: UserDataModel
    @State var showAlert: Bool = false
    @State var selectedIndexGender = 0
    @State var selectedIndexPlan = 0
    @State var trainingDay = 0
    @State var activitieDay = 0
    
    func isSheetEnabled() -> Bool {
        if enableWeightSheet || enableHeightSheet  {
            return true
        } else {
            return  false
        }
    }

    var body: some View {
        
        
        ZStack{
            VStack{
                Form{
                    Section("Persoonlijke gegevens") {
                        
                        Picker(selection: $selectedIndexGender, label: Text("Geslacht"), content:{
                                            Text("Man").tag(0)
                                            Text("Vrouw").tag(1)
                        })
                            .pickerStyle(SegmentedPickerStyle())
                        
                        VStack {
                            HStack{
                            Text("Geboortedatum")
                                DatePicker("", selection: $birthDate, displayedComponents: .date)
                                }
                                    }
                        
                        HStack{
                            Text("Gewicht")
                            Spacer()
                                Button("\(weight)"){
                                self.enableWeightSheet.toggle()
                                    }
                                        }
                                .padding([.top, .bottom], 2.5)
                        
                        HStack{
                            Text("Lengte")
                            Spacer()
                                Button("\(height)"){
                                self.enableHeightSheet.toggle()
                                    }
                                        }
                            .padding([.top, .bottom], 2.5)
                    }
                    Section("plan") {
                        
                    Picker(selection: $selectedIndexPlan, label: Text("Geslacht"), content:{
                        Text("Afvallen").tag(0)
                        Text("onderhouden").tag(1)
                        Text("Bulken").tag(2)
                    })
                        .pickerStyle(SegmentedPickerStyle())
                        
                        
                        Picker(selection: $trainingDay, label: Text("Aantal trainingen")) {
                            ForEach(0..<8) {
                                Text("\($0) per week").tag($0)
                            }
                        }
                        Picker(selection: $activitieDay, label: Text("Activiteitenniveau")) {
                            Text("Niet actief").tag(0)
                            Text("Licht actief").tag(1)
                            Text("Redelijk actief").tag(2)
                            Text("Zeer actief").tag(3)
                        }
                    }
                }
            }
        }
            
        if enableWeightSheet {
            InitializeWeight(enableWeightSheet: $enableWeightSheet, weight: $weight, height: $height)
        }
        
        if enableHeightSheet {
            InitializeHeight(enableHeightSheet: $enableHeightSheet, heigth: $height)
        }
    }
}

struct SecondRegister_Previews: PreviewProvider {
    static var previews: some View {
        SecondRegister()
    }
}
