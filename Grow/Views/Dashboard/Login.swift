//
//  Login.swift
//  Grow
//
//  Created by Swen Rolink on 10/12/2021.
//

import SwiftUI
import Firebase

struct Login: View {
    
    enum FocusFields {
        case username, password
    }
    
    @ObservedObject var userSettings = UserSettings()
    @FocusState private var focusedField: FocusFields?
    @State private var showActivityIndicator = false
    @State private var alertText = ""
    @State private var showAlert: Bool = false
    
    func login(){
        
        self.showActivityIndicator = true
        
        Auth.auth().signIn(withEmail: userSettings.username, password: userSettings.password) {
            authResult, error in
            
            self.showActivityIndicator.toggle()
            
            if (error?.localizedDescription != nil){
                self.alertText = error?.localizedDescription ?? "Aanmelden mislukt"
                self.showAlert.toggle()
            }else if(authResult?.user != nil){
                // success!
            } else {
                self.alertText = "Aanmelden mislukt"
                self.showAlert.toggle()
            }
        }
    }
    
    func register(){
        //Do seomthing
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 15){
            ScrollView(showsIndicators: false){
                
                Text("Welkom!")
                  .font(.largeTitle).foregroundColor(Color.black)
                  .padding([.top, .bottom], 40)
                            
                Image("menuImage")
                  .resizable()
                  .frame(width: 150, height: 150)
                  .shadow(radius: 10)
                  .padding(.bottom, 50)
                
                TextField("E-mail", text: $userSettings.username)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .username)
                    .cornerRadius(15.0)
                
                SecureField("Password", text: $userSettings.password)
                    .padding()
                    .background(Color.init("textField"))
                    .focused($focusedField, equals: .password)
                    .cornerRadius(15.0)
                
                Button("Login", action: login)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
          
                
                Button("Registreren", action: register)
                    .buttonStyle(LinkButtonStyle())
                    .padding([.bottom], 20)

                
            }
        }
        .alert(isPresented: self.$showAlert) {
            Alert(title: Text("Error"), message: Text(self.alertText), dismissButton: .default(Text("Ok")))
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
        .padding([.leading, .trailing], 27.5)
        .background(
            LinearGradient(gradient: Gradient(colors: [.white, Color.init("BackgroundForm")]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all).opacity(0.5))
        .onSubmit {
            if focusedField == .username {
                focusedField = .password
            } else {
                focusedField = nil
            }
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
