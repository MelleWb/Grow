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
    @State var showActivityIndicator = false
    
    var showAuthResult: String = ""
        
        func setAuthDetails() -> String {
            if (fbAuth.isAuthenticated == true) {
                showActivityIndicator = false
                return "Gelukt"
            }
            else if fbAuth.errorText != "" {
                showActivityIndicator = false
                return fbAuth.errorText
            }
            else {
                return ""
            }
        }
    
        var body: some View{
            
            ProgressIndicator(isShowing: $showActivityIndicator, loadingText: "Inloggen", content:{
                
            VStack {
                WelcomeText()
                LoginImage()
                
                Section {
                    UsernameTextField(username: $userSettings.username)
                    PasswordSecureField(password: $userSettings.password)
                    Text(setAuthDetails())
                     .offset(y: -10)
                     .foregroundColor(.red)
                     
                }

                Button(action: {
                    self.showActivityIndicator = true
                    fbAuth.signIn(username: userSettings.username, password: userSettings.password)
                })
                {
                    LoginButtonContent()
                }
            .offset(y: -keyboardResponder.currentHeight*0.4)
            .padding()
            .environmentObject(fbAuth)
            }
            })
        }
}
    
struct UsernameTextField : View {
    @Binding var username: String
    var body: some View {
        return TextField("Gebruikersnaam", text: $username)
                .padding()
                .background(Color.init("textField"))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
    }
}

struct PasswordSecureField : View {
    
    @Binding var password: String
    
    var body: some View {
        return SecureField("Wachtwoord", text: $password)
            .padding()
            .background(Color.init("textField"))
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
            .background(Color.init("buttonColor"))
            .cornerRadius(15.0)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
