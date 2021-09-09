//
//  SwiftUIView.swift
//  Pods
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import Firebase
import FirebaseStorage
import KeyboardToolbar

struct UpdateProfile: View {

    @Binding var showProfileView: Bool
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State var originalImage: UIImage?
    
    let toolbarItems: [KeyboardToolbarItem] = [.dismissKeyboard]
    
    var body: some View {

            Form {
                Section {
                    PersonalDetails(originalImage: $originalImage)

                    DateOfBirth()

                    WeightHeight()

                    Gender()

                    Plan()

                    PalValue()

                    ModifyKcal()

                    WorkOutSchema()
                    
                    Button(action: {
                                   let firebaseAuth = Auth.auth()
                                  do {
                                    try firebaseAuth.signOut()
                                    self.showProfileView = false
                                  } catch let signOutError as NSError {
                                    print ("Error signing out: %@", signOutError)
                                  }
                               })
                               {
                                   Text("Uitloggen")
                                       .font(.headline)
                                       .foregroundColor(.white)
                                       .padding()
                                       .frame(width: 200, height: 60, alignment: .center)
                                       .background(Color.init("buttonColor"))
                                       .cornerRadius(15.0)
                               }.padding()
                }
                
                .pickerStyle(DefaultPickerStyle())
                .onAppear(perform:{self.originalImage = self.userModel.userImages.userImage})
                
                }
            .accentColor(.accentColor)
            .keyboardToolbar(toolbarItems)
                .navigationBarTitle(Text("Profiel"), displayMode: .inline)
                   .navigationBarItems(trailing: Button(action: {
                    
                    if originalImage != nil {
                        self.userModel.uploadPicture(for: originalImage!)
                        }
                    
                    //Update the user and reinitiate the foodmodel
                    self.userModel.updateUser()
                    self.foodModel.resetUser(user: self.userModel.user)
                    self.trainingModel.resetUser(user: self.userModel.user)
                    self.statisticsModel.resetUser(user: self.userModel.user)
                    //dismiss the sheet
                    self.showProfileView = false
                   
                   }) {
                    Text("Klaar").bold().foregroundColor(Color.init("textColor"))
                   })
        }
}


struct PersonalDetails: View {
    @EnvironmentObject var userModel : UserDataModel

    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @Binding var originalImage: UIImage?
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        originalImage = inputImage
    }
    
    var body: some View {
        HStack{
            if originalImage != nil {
                Image(uiImage: originalImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75, alignment: .leading)
                    .shadow(radius: 10)
                    .clipShape(Circle())
                    .onTapGesture {
                        self.showingImagePicker = true
                    }
            } else {
                Image("profile")
                    .resizable()
                    .frame(width: 75, height: 75, alignment: .leading)
                    .shadow(radius: 10)
                    .clipShape(Circle())
                    .onTapGesture {
                        self.showingImagePicker = true
                }
            }

            VStack{
                FirstName()
                LastName()
            }
        }.padding()
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
    }
}

struct FirstName : View {
    
    @EnvironmentObject var userModel: UserDataModel

    var body: some View {
        
        let firstName = Binding(
            get: { self.userModel.user.firstName ?? "" },
            set: { self.userModel.updateUserModel(for: "firstName", to: $0) }
        )
        
        return TextField("Voornaam", text: firstName)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.bottom, 10)
    }
}

struct LastName : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        let lastName = Binding(
            get: { self.userModel.user.lastName ?? "" },
            set: { self.userModel.updateUserModel(for: "lastName", to: $0) }
        )
        
        return TextField("Achternaam", text: lastName)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.bottom, 10)
    }
}

struct DateOfBirth : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        let dateOfBirth = Binding(
            get: { self.userModel.user.dateOfBirth ?? DateHelper.from(year: 1970, month: 1, day: 1)},
            set: { self.userModel.updateUserModel(for: "dateOfBirth", to: $0) }
        )
        
        return
            DatePicker("Geboortedatum", selection: dateOfBirth, displayedComponents: .date)
            .datePickerStyle(CompactDatePickerStyle())
                .frame(maxHeight: 400)
            .padding()
    }
}

struct Gender : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        let gender = Binding(
            get: { self.userModel.user.gender ?? 0 },
            set: { self.userModel.updateUserModel(for: "gender", to: $0) }
        )
        
        return
            VStack{
                Picker(selection: gender, label: Text("Geslacht"), content:{
                                    Text("Man").tag(0)
                                    Text("Vrouw").tag(1)
                }).padding()
            }
    }
}

struct WeightHeight : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View{
        
        let weightProxy = Binding<String>(
            get: { String(self.userModel.user.weight ?? 0) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.userModel.updateUserModel(for: "weight", to: value.intValue)
                }
            }
        )
        
        let heightProxy = Binding<String>(
            get: { String(self.userModel.user.height ?? 0) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.userModel.updateUserModel(for: "height", to: value.intValue)
                }
            }
        )
        
        return HStack {
            VStack(alignment:.leading){
            Text("Gewicht")
            TextField("Gewicht", text: weightProxy)
                .padding()
                .keyboardType(.decimalPad)
                .background(Color.init("textField"))
                .cornerRadius(5.0)
            }
            Spacer()

            
            VStack(alignment:.leading) {
            Text("Lengte")
            TextField("Lengte", text: heightProxy)
                .padding()
                .keyboardType(.decimalPad)
                .background(Color.init("textField"))
                .cornerRadius(5.0)
            }
            Spacer()
            
        }.padding()
            
    }
}

struct Plan : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        let plan = Binding(
            get: { self.userModel.user.plan ?? 0 },
            set: { self.userModel.updateUserModel(for: "plan", to: $0) }
        )
        
        return
            Picker(selection: plan, label: Text("Plan")) {
                                Text("Cut").tag(0)
                                Text("Onderhoud").tag(1)
                                Text("Bulk").tag(2)
                        }.padding()
    }
}


struct PalValue : View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        let palValue = Binding(
            get: { self.userModel.user.pal ?? 0 },
            set: { self.userModel.updateUserModel(for: "pal", to: $0) }
        )
        
        return
            Section {
            Picker(selection: palValue, label: Text("Trainingen")) {
                                Text("1 a 2 keer per week").tag(0)
                                Text("3 a 4 keer per week").tag(1)
                                Text("4 a 5 keer per week").tag(2)
                                Text("6 a 7 keer per week").tag(3)
                        }.padding()
            }
    }
}

struct ModifyKcal : View {
    @EnvironmentObject var userModel: UserDataModel
    @State var proteinRatioInput: String = ""
    @State var fatRatioInput: String = ""
    @State var proteinPlaceholder: String = ""
    @State var fatPlaceholder: String = ""
    
    var body: some View {
        
        let kcalBinding = Binding<String> {
            String(self.userModel.user.kcal ?? 0)
        } set: { kcal in
            if let value = NumberFormatter().number(from: kcal) {
                self.userModel.user.kcal = value.intValue
            }
        }
        
        let proteinBinding = Binding<String>(get: {
            self.proteinRatioInput
        }, set: {protein in
            if let value = NumberFormatter().number(from: protein){
                self.userModel.user.proteinRatio = value.doubleValue
            }
            self.proteinRatioInput = protein
        })

        let fatBinding = Binding<String>(get: {self.fatRatioInput}, set: {fat in
            if let value = NumberFormatter().number(from: fat){
                self.userModel.user.fatRatio = value.doubleValue
            }
            self.fatRatioInput = fat
        })
        
        return
            Section{
                VStack(alignment: .leading){
                        Text("Caloriënbudget op een rustdag")
                        TextField(String(self.userModel.user.kcal ?? 0), text:kcalBinding)
                            .padding()
                            .keyboardType(.numberPad)
                            .background(Color.init("textField"))
                            .cornerRadius(5.0)
                    
                    Text("Op een sportdag \(String((Double(self.userModel.user.kcal ?? 1)*1.1).rounded())) kcal")
                }.padding()
                    
                        VStack(alignment: .leading){
                            Text("Eiwit ratio (1.6 en 2.0)")
                            TextField(proteinPlaceholder, text: proteinBinding)
                                .padding()
                                .keyboardType(.decimalPad)
                                .background(Color.init("textField"))
                                .cornerRadius(5.0)
                        }.padding()
                        VStack(alignment: .leading){
                            Text("Vet percentage (ongeveer 30%)")
                            TextField(fatPlaceholder, text: fatBinding)
                                .padding()
                                .keyboardType(.decimalPad)
                                .background(Color.init("textField"))
                                .cornerRadius(5.0)
                        }.padding()
            }.onAppear(perform: {
                self.proteinPlaceholder = String(self.userModel.user.proteinRatio ?? 2)
                self.fatPlaceholder = String(self.userModel.user.fatRatio ?? 30)
            })
    }
}

struct WorkOutSchema : View {
    
    @EnvironmentObject var userModel: UserDataModel
    var body: some View {

        return
            Section() {
                List{
                    NavigationLink(destination: SelectWorkOutSchema()){
                        Text("Selecteer een trainingsschema")
                    }
                }.padding()
        }
    }
}

struct SelectWorkOutSchema:View {
    
    @EnvironmentObject var userModel: UserDataModel
    @ObservedObject var schemaModel = TrainingDataModel()
    @State var searchText = ""
    @State var searching = false
    @State var selectedSchema: String?
    
    var body: some View {
        List{
            SearchBar(searchText: $searchText, searching: $searching)
            ForEach(schemaModel.fetchedSchemas.filter({ (schema: Schema) -> Bool in
                return schema.name.hasPrefix(searchText) || searchText == ""
            }), id: \.self){ schema in
                SelectWorkoutCell(schema: schema, selectedSchema: self.$selectedSchema)
                }
            }.padding()
        .onAppear(perform:{
                self.schemaModel.fetchData()
                self.selectedSchema = userModel.user.schema
            })
        .onDisappear(perform: {
            if self.selectedSchema != nil {
                self.userModel.updateUserModel(for: "workoutSchema", to: selectedSchema!)
            }
            print("onDisAppear")
        })
        .navigationTitle(Text("Selecteer een schema"))
    }
    }


struct SelectWorkoutCell:View{
    
    var schema: Schema
    @Binding var selectedSchema: String?
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var schemaModel: TrainingDataModel

    var body: some View {
        HStack {
            if selectedSchema == schema.docID  {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            else {
                Image(systemName: "circle")
                    .foregroundColor(.accentColor)
            }
            
            Text(schema.name).font(.headline)

        }
        .onTapGesture {
                self.selectedSchema = schema.docID
                }
            }
        }
