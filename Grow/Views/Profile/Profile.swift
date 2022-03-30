//
//  Profile.swift
//  Grow
//
//  Created by Swen Rolink on 03/12/2021.
//

import SwiftUI
import Introspect
import Firebase

struct Profile: View {
    
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    
    @State var enableWeightSheet: Bool = false
    @State var enableHeightSheet: Bool = false
    @State var showAlert: Bool = false
    
    @State private var searchTermTraining: String = ""
    
    func isSheetEnabled() -> Bool {
        if enableWeightSheet || enableHeightSheet {
            return true
        } else {
            return  false
        }
    }
    
    var filteredSchemas: [Schema] {
        self.trainingModel.fetchedSchemas.filter {
            searchTermTraining.isEmpty ? true : $0.name.lowercased().contains(searchTermTraining.lowercased())
            }
        }
    
    var body: some View {
        ZStack{
            VStack{
                Form{
                    Section("Persoonlijke gegevens") {
                        
                        let genderBinding = Binding(
                            get: { self.userModel.user.gender ?? 0 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .Gender, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        Picker(selection: genderBinding, label: Text("Geslacht"), content:{
                                            Text("Man").tag(0)
                                            Text("Vrouw").tag(1)
                        })
                            .pickerStyle(SegmentedPickerStyle())
                        
                        let firstNameBinding = Binding<String>(
                            get: { self.userModel.user.firstName ?? "" },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .FirstName, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        HStack{
                            Text("Voornaam")
                            Spacer()
                            TextField("Je voornaam", text: firstNameBinding)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        let lastNameBinding = Binding<String>(
                            get: { self.userModel.user.lastName ?? "" },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .LastName, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        HStack{
                            Text("Achternaam")
                            Spacer()
                            TextField("Je achternaam", text: lastNameBinding)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        let dateOfBirthBinding = Binding<Date>(
                            get: { self.userModel.user.dateOfBirth ?? Date() },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .DateOfBirth, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        DatePicker("Geboortedatum", selection: dateOfBirthBinding, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            
                        HStack{
                            Text("Lengte")
                            Spacer()
                            Button("\(self.userModel.user.height ?? 1)"){
                                self.enableHeightSheet.toggle()
                            }
                        }
                        
                        HStack{
                            Text("Gewicht")
                            Spacer()
                            Button("\(self.userModel.user.weight ?? 1)"){
                                self.enableWeightSheet.toggle()
                            }
                        }
                    }
                    Section("Plan"){
                        
                        let planBinding = Binding(
                            get: { self.userModel.user.plan ?? 0 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .Plan, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        Picker(selection: planBinding, label: Text("Plan"), content:{
                            Text("Afvallen").tag(0)
                            Text("Onderhouden").tag(1)
                            Text("Bulken").tag(2)
                        })
                            .pickerStyle(SegmentedPickerStyle())
                        
                        let nmbrTrainingBinding = Binding(
                            get: { self.userModel.user.nmbrOfTrainings ?? 0 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .NmbrOfTrainings, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        Picker(selection: nmbrTrainingBinding, label: Text("Aantal trainingen")) {
                            ForEach(0..<8) {
                                Text("\($0) per week").tag($0)
                            }
                        }
                        
                        let palBinding = Binding(
                            get: { self.userModel.user.pal ?? 0 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .Pal, to: $0)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        Picker(selection: palBinding, label: Text("Activiteitenniveau")) {
                            Text("Niet actief").tag(0)
                            Text("Licht actief").tag(1)
                            Text("Redelijk actief").tag(2)
                            Text("Zeer actief").tag(3)
                        }
                    }
                    Section("Voeding"){
                        HStack{
                            NavigationLink(destination: CalorieOverview()) {
                                Text("Calorie budget")
                            }
                        }
                    }
                    Section("Trainingschema") {
                        
                        let trainingSchemaBinding = Binding(
                            get: { self.userModel.user.schema },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .WorkoutSchema, to: $0!)
                                    }
                                    catch{
                                        self.showAlert.toggle()
                                    }
                                }
                        )
                        
                        Picker(selection: trainingSchemaBinding, label: Text("Trainingschema")) {
                            PickerSearchBar(text: $searchTermTraining, placeholder: "Schema zoeken")
                            ForEach(filteredSchemas, id:\.self) { schema in
                                Text(schema.name).tag(schema.docID)
                            }
                        }
                    }
                    HStack{
                        Spacer()
                        
                        Button("Opslaan") {
                            self.userModel.updateUser()
                            self.foodModel.resetUser(user: self.userModel.user)
                            self.trainingModel.resetUser(user: self.userModel.user)
                            self.statisticsModel.resetUser(user: self.userModel.user)
                        }.foregroundColor(.accentColor)
                            .font(.headline)

                        Spacer()
                    }
                }
            }
            .introspectTabBarController { (UITabBarController) in
                if isSheetEnabled() {
                    UITabBarController.tabBar.isHidden = true
                } else {
                    UITabBarController.tabBar.isHidden = false
                }
            }
            .navigationTitle(Text("Profiel"))
            
            .navigationBarHidden(isSheetEnabled())
            .navigationBarBackButtonHidden(isSheetEnabled())
            
            .navigationBarItems(trailing:
                Button("Uitloggen"){
                    do {
                     try Auth.auth().signOut()
                    }
                        catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                   }
                }
            )
            
            if enableWeightSheet {
                WeightActionSheet(enableWeightSheet: $enableWeightSheet)
            }
            
            if enableHeightSheet {
                HeightActionSheet(enableHeightSheet: $enableHeightSheet)
            }
            
        }
        
    }
}
