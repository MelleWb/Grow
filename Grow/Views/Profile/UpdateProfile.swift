//
//  SwiftUIView.swift
//  Pods
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct UpdateProfile: View {

    @Binding var showProfileSheetView: Bool
    @EnvironmentObject var userModel: UserDataModel
    @State var originalImage: UIImage?

    func calcKcal(weight: Double, height: Double, dateOfBirth: Date, gender: Int, palOption: Int) -> Int {
        
            let today = Date()
    
            let yearCompOfToday = Calendar.current.dateComponents([.year], from: today)
            let yearOfToday = yearCompOfToday.year ?? 0
            
            let yearCompOfUser = Calendar.current.dateComponents([.year], from: dateOfBirth)
            let yearOfUser = yearCompOfUser.year ?? 0
            
            let ageNumber = yearOfToday - yearOfUser
            
            var palValue: Double
            
            if   palOption == 0 {
                palValue = 1.2
            } else if palOption == 1 {
                palValue = 1.375
            } else if palOption == 2 {
                palValue = 1.55
            } else if palOption == 3 {
                palValue = 1.725
            } else {
                palValue = 1.4
            }
            
            if gender == 0 {
                let calc1 = 66 + (13.7 * weight)
                let kcal = calc1 + (5 * height) - (6.8 * Double(ageNumber))
                
                if userModel.user.plan == 0{
                        return Int((kcal * palValue) * 0.82)
                    }
                    else if userModel.user.plan == 1{
                        return Int(kcal * palValue)
                    }
                    else{
                        return Int((kcal * palValue) * 1.1)
                    }
            }
            else {
                let calc1 = 447.593 + (9.247 * weight)
                let kcal = calc1 + (3.098 * height) - (4.33 * Double(ageNumber))
                
                    if userModel.user.plan == 0{
                        return Int((kcal * palValue) * 0.82)
                    }
                    else if userModel.user.plan == 1{
                        return Int(kcal * palValue)
                    }
                    else{
                        return Int((kcal * palValue) * 1.2)
                    }
                }
        }
    
    func calcProtein(weight: Int) -> Int{
        return Int(Double(weight) * 1.9)
    }
    
    func calcFat(kcal: Int) -> Int {
        return Int(Double(kcal) * 0.3/9)
    }
    
    func calcCarbs(kcal: Int, protein: Int, fat: Int) -> Int {
        let proteinKcal = protein * 4
        let fatKcal = fat * 9
        return Int((kcal - proteinKcal - fatKcal)/4)
    }
    
    func calcFiber(kcal: Int) -> Int {
        return Int(Double(kcal) * 0.014)
    }
    
    var body: some View {
        
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading){
                        PersonalDetails(originalImage: $originalImage).environmentObject(userModel)
                        }.padding()
                    }
                Section {
                    DateOfBirth().environmentObject(userModel)
                }.padding()
                Section {
                    WeightHeight().environmentObject(userModel)
                }.padding()
                Section{
                    Gender().environmentObject(userModel)
                }.padding()
                .pickerStyle(DefaultPickerStyle())
                Section {
                    Plan().environmentObject(userModel)
                }.padding()
                .pickerStyle(DefaultPickerStyle())
                Section {
                    PalValue().environmentObject(userModel)
                }.padding()
                Section {
                    WorkOutSchema().environmentObject(userModel)
                }.padding()
                
                .pickerStyle(DefaultPickerStyle())
                .onAppear(perform:{self.originalImage = self.userModel.userImages.userImage?.image})
                
                }
                .accentColor(Color.init("textColor"))
                .navigationBarTitle(Text("Profiel"), displayMode: .inline)
                   .navigationBarItems(trailing: Button(action: {
                    
                    if originalImage != nil {
                        self.userModel.uploadPicture(for: originalImage!)
                        }
                    
                    //Update the user
                    
                    self.userModel.updateUser()
                    //dismiss the sheet
                    self.showProfileSheetView = false
                   
                   }) {
                    Text("Klaar").bold().foregroundColor(Color.init("textColor"))
                   })
        }
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
                FirstName().environmentObject(userModel)
                LastName().environmentObject(userModel)
            }
        }
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

struct WorkOutSchema : View {
    
    @EnvironmentObject var userModel: UserDataModel
    @ObservedObject var schemaModel = TrainingDataModel()
    
    var body: some View {
        
        let schema = Binding(
            get: { self.userModel.user.schema ?? "" },
            set: { self.userModel.updateUserModel(for: "workoutSchema", to: $0) }
        )
        
        return
            Section {
            Picker(selection: schema, label: Text("Trainingsschema")) {
                ForEach(schemaModel.fetchedSchemas, id: \.self){ schema in
                    Text(schema.name).tag(schema.name)
                }
                        }.padding()
            }.onAppear(perform:{self.schemaModel.fetchData()})
    }
}
