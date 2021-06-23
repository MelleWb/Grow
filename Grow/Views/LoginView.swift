//
//  LoginView.swift
//  Grow
//
//  Created by Swen Rolink on 20/06/2021.
//

import SwiftUI
import Combine
import Firebase

struct LoginView : View {
    
    @StateObject var fbAuth = FirebaseAuthentication()
    @ObservedObject var keyboardResponder = KeyboardResponder()
    @ObservedObject var userSettings = UserSettings()
    
    @State var isShowing: Bool = false
    
    var showAuthResult: String = ""
        
        func setAuthDetails() -> String {
            if (fbAuth.isAuthenticated == true) {
                return "Gelukt"
            }
            else if fbAuth.errorText != "" {
                return fbAuth.errorText
            }
            else {
                return ""
            }
        }
    
        var body: some View{
            ProgressIndicator(isShowing: $isShowing) {
            VStack {
                WelcomeText()
                LoginImage()
                
                UsernameTextField(username: $userSettings.username)
                PasswordSecureField(password: $userSettings.password)
                
                   Text(setAuthDetails())
                    .offset(y: -10)
                    .foregroundColor(.red)
                
                Button(action: {
                    self.isShowing = true
                    fbAuth.signIn(username: userSettings.username, password: userSettings.password)
                    self.isShowing = false
                })
                {
                    LoginButtonContent()
                }
                
                
            }
            .offset(y: -keyboardResponder.currentHeight*0.4)
            .padding()
            .environmentObject(fbAuth)
            }
        }
}
    
struct UsernameTextField : View {
    @Binding var username: String
    var body: some View {
        return TextField("Gebruikersnaam", text: $username)
                .padding()
                .background(Color.init("lightGrey"))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
    }
}

struct PasswordSecureField : View {
    
    @Binding var password: String
    
    var body: some View {
        return SecureField("Wachtwoord", text: $password)
            .padding()
            .background(Color.init("lightGrey"))
            .cornerRadius(5.0)
            .padding(.bottom, 20)
    }
}

struct WelcomeText : View {
    var body: some View{
        return Text("Welkom!")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct LoginImage : View {
    var body: some View {
        return Image("menuImage")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .padding(.bottom, 75)
    }
}

struct LoginButtonContent : View {
    var body : some View {
        return Text("Login")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.init("textColor"))
            .cornerRadius(15.0)
    }
}

class FirebaseAuthentication: ObservableObject {
    
    @Published var authObject: AuthDataResult?
    @Published var errorText: String = ""
    @Published var isAuthenticated: Bool = false
    
    func signIn(username: String, password: String){
        Auth.auth().signIn(withEmail: username, password: password) {
            authResult, error in
            
            if (error?.localizedDescription != nil){
                print(error!.localizedDescription)
                DispatchQueue.main.async {
                    self.errorText = error!.localizedDescription
                }
            }else if(authResult?.user != nil){
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.authObject = authResult
                }
            } else {
                print("Geen authenticatie")
            }
        }
    }
    
    func getStatus(){
        Auth.auth().addStateDidChangeListener { auth, user in
          if user != nil {
            // User is signed in. Show home screen
          } else {
            // No User is signed in. Show user the login screen
          }
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
