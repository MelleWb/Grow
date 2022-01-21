//
//  Register.swift
//  Grow
//
//  Created by Melle Wittebrood on 31/12/2021.
//

import SwiftUI
import Firebase

struct Register: View {
    
    enum FocusFields {
        case new_firstname, new_lastname, new_username, new_password, confirm_password
    }
    
    @State var registerButtonTapped = false
    @State var new_firstname: String = ""
    @State var new_lastname: String = ""
    @State var new_username: String = ""
    @State var new_password: String = ""
    @State var confirm_password: String = ""
    @State var isEmailValid : Bool   = true
    @State var birthDate = Date()
    @FocusState private var focusedField: FocusFields?
    
    func checkPassword() {
        if new_password == confirm_password {
                print("is hetzelfde")
            } else {
                print("is niet het zelfde")
            }
      }
    
    func textFieldValidatorEmail(_ string: String) -> Bool {
        if string.count > 100 {
            return false
        }
        let emailFormat = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" + "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        //let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: string)
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 15){
            ScrollView(showsIndicators: false){
                VStack{
                
                VStack{
                Text("Maak een account!")
                  .font(.largeTitle).foregroundColor(Color.black)
                  .padding([.top, .bottom], 20)
                }
                
                TextField("Voornaam", text: $new_firstname)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .new_username)
                    .cornerRadius(15.0)
                    .padding([.leading, .trailing], 30)
                
                TextField("Achternaam", text: $new_lastname)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .new_username)
                    .cornerRadius(15.0)
                    .padding([.leading, .trailing], 30)
                
            VStack{
                TextField("email", text: $new_username, onEditingChanged: { (isChanged) in
                    if !isChanged {
                        if self.textFieldValidatorEmail(self.new_username) {
                            self.isEmailValid = true
                        } else {
                            self.isEmailValid = false
                            self.new_username = ""
                        }
                    }
                }).padding()
                .background(Color.init("textField"))
                .focused($focusedField, equals: .new_password)
                .cornerRadius(15.0)
                .padding([.leading, .trailing], 30)

            if !self.isEmailValid {
                Text("Email is niet juist")
                .font(.callout)
                .foregroundColor(Color.red)
                }
            }
                SecureField("Wachtwoord", text: $new_password)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .new_password)
                    .cornerRadius(15.0)
                    .padding([.leading, .trailing], 30)
                
                SecureField("bevestig Wachtwoord", text: $confirm_password)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .confirm_password)
                    .cornerRadius(15.0)
                    .padding([.leading, .trailing], 30)
                
                VStack {
                    HStack{
                        Text("Geboortedatum")
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                    }
                }.padding([.leading, .trailing], 30)
                
                VStack {
                    HStack{
                        Text("Gewicht")
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                    }
                }.padding([.leading, .trailing], 30)
                    
                VStack {
                    HStack{
                        Text("Lengte")
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                    }
                }.padding([.leading, .trailing], 30)
        
                    Button(action: {
                        checkPassword()
                    }, label: {
                        Text("Aanmelden")
                            .buttonStyle(PrimaryButtonStyle())
                            .padding()
                    })
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button(action: {
                    focusedField = nil
                },label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(.accentColor)
                })
            }
        }
    }
}

struct Register_Previews: PreviewProvider {
    static var previews: some View {
        Register()
    }
}
