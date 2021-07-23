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
    @StateObject var userModel: UserDataModel
    
    @State var firstName:String
    @State var lastName:String
    @State var dateOfBirth:Date
    @State var gender:Int
    @State var weight: Int
    @State var height: Int
    @State var plan:Int
    @State var kcal: Int
    @State var palOption: Int
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
                
                    if plan == 0{
                        return Int((kcal * palValue) * 0.82)
                    }
                    else if plan == 1{
                        return Int(kcal * palValue)
                    }
                    else{
                        return Int((kcal * palValue) * 1.1)
                    }
            }
            else {
                let calc1 = 447.593 + (9.247 * weight)
                let kcal = calc1 + (3.098 * height) - (4.33 * Double(ageNumber))
                
                    if plan == 0{
                        return Int((kcal * palValue) * 0.82)
                    }
                    else if plan == 1{
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    var body: some View {
        
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading){
                        PersonalDetails(firstName: $firstName, lastName: $lastName, originalImage: $originalImage)
                        }.padding()
                    }
                Section {
                    DateOfBirth(dateOfBirth: $dateOfBirth)
                }.padding()
                Section {
                    WeightHeight(height: $height, weight: $weight)
                }.padding()
                Section{
                    Gender(gender: $gender)
                }.padding()
                .pickerStyle(DefaultPickerStyle())
                Section {
                    Plan(plan:$plan)
                }.padding()
                .pickerStyle(DefaultPickerStyle())
                Section {
                    PalValue(palOption: $palOption)
                }.padding()
                .pickerStyle(DefaultPickerStyle())
                }
               .navigationBarTitle(Text("Profiel"), displayMode: .inline)
                   .navigationBarItems(trailing: Button(action: {
                    
                    if originalImage != nil {
                        let storageRef = Storage.storage().reference().child(userModel.user.id ?? "UserPicture \((UUID()))")
                        
                        let compressedImage: UIImage = self.resizeImage(image:originalImage!, targetSize: CGSize(width: 500, height: 500))!
                        
                        if let uploadData = compressedImage.pngData(){
                            storageRef.putData(uploadData, metadata: nil, completion: {(metadata, error)in
                                if error != nil {
                                    print("error")
                                    setUserObject()
                                    return
                                }
                                else {
                                    storageRef.downloadURL(completion: {(url, error) in
                                        print("Image URL: \((url?.absoluteString)!)")
                                        self.userModel.user.userImageURL = url?.absoluteString
                                        setUserObject()
                                    })
                                }
                            })
                        }
                    } else {
                        print ("Nil")
                        setUserObject()
                    }
                    
                    func setUserObject() {
                        var updatedUserObject = User()
                        updatedUserObject.id = userModel.user.id
                        updatedUserObject.firstName = self.firstName
                        updatedUserObject.lastName = self.lastName
                        updatedUserObject.dateOfBirth = self.dateOfBirth
                        updatedUserObject.gender = self.gender
                        updatedUserObject.weight = self.weight
                        updatedUserObject.height = self.height
                        updatedUserObject.plan = self.plan
                        updatedUserObject.gender = self.gender
                        updatedUserObject.pal = self.palOption
                        updatedUserObject.kcal = calcKcal(weight: Double(updatedUserObject.weight ?? 0), height: Double(updatedUserObject.height ?? 0), dateOfBirth: updatedUserObject.dateOfBirth ?? DateHelper.from(year: 1990, month: 1, day: 1), gender: updatedUserObject.gender ?? 0, palOption: updatedUserObject.pal ?? 0)
                        updatedUserObject.protein = calcProtein(weight: updatedUserObject.weight ?? 0)
                        updatedUserObject.fat = calcFat(kcal: updatedUserObject.kcal ?? 0)
                        updatedUserObject.carbs = calcCarbs(kcal: updatedUserObject.kcal ?? 0, protein: updatedUserObject.protein ?? 0, fat: updatedUserObject.fat ?? 0)
                        updatedUserObject.fiber = calcFiber(kcal: updatedUserObject.kcal ?? 0)
                        updatedUserObject.userImageURL = userModel.user.userImageURL
                        
                        
                        let settings = FirestoreSettings()
                        settings.isPersistenceEnabled = true
                        let db = Firestore.firestore()
                        
                        let docRef = db.collection("users").document(userModel.user.id!)
                        do {
                            try docRef.setData(from: updatedUserObject, merge: true)
                            //Overwrite the user model with new data
                            userModel.user = updatedUserObject

                        }
                        catch {
                          print(error)
                        }
                    }
                    
                    //dismiss the sheet
                    self.showProfileSheetView = false
                   
                   }) {
                    Text("Klaar").bold()
                   })
            }
        }
}


struct PersonalDetails: View {
    @Binding var firstName:String
    @Binding var lastName:String
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
                FirstName(firstName: $firstName)
                LastName(lastName: $lastName)
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
    }
}

struct FirstName : View {
    @Binding var firstName: String
    var body: some View {
        return TextField("Voornaam", text: $firstName)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.bottom, 10)
    }
}

struct LastName : View {
    @Binding var lastName: String
    var body: some View {
        return TextField("Achternaam", text: $lastName)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.bottom, 10)
    }
}

struct DateOfBirth : View {
    
    @Binding var dateOfBirth: Date
    
    var body: some View {
        return
            DatePicker("Geboortedatum", selection: $dateOfBirth, displayedComponents: .date)
            .datePickerStyle(CompactDatePickerStyle())
                .frame(maxHeight: 400)
    }
}

struct Gender : View {
    
    @Binding var gender: Int
    
    var body: some View {
        return
            VStack{
                Picker(selection: $gender, label: Text("Geslacht"), content:{
                                    Text("Man").tag(0)
                                    Text("Vrouw").tag(1)
                }).padding()
            }
    }
}

struct WeightHeight : View {
    
    
    @Binding var height: Int
    @Binding var weight: Int
    
    var body: some View{
        
        let weightProxy = Binding<String>(
            get: { String(Int(self.weight)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.weight = value.intValue
                }
            }
        )
        
        let heightProxy = Binding<String>(
            get: { String(Int(self.height)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.height = value.intValue
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
    
    @Binding var plan: Int
    
    var body: some View {
        return
            Picker(selection: $plan, label: Text("Plan")) {
                                Text("Cut").tag(0)
                                Text("Onderhoud").tag(1)
                                Text("Bulk").tag(2)
                        }.padding()
    }
}


struct PalValue : View {
    
    @Binding var palOption: Int
    
    var body: some View {
        
        return
            Section {
            Picker(selection: $palOption, label: Text("Trainingen")) {
                                Text("1 a 2 keer per week").tag(0)
                                Text("3 a 4 keer per week").tag(1)
                                Text("4 a 5 keer per week").tag(2)
                                Text("6 a 7 keer per week").tag(3)
                        }.padding()
            }
    }
}
