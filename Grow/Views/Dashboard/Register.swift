//
//  Register.swift
//  Grow
//
//  Created by Melle Wittebrood on 31/12/2021.
//

import SwiftUI

struct Register: View {
    
    enum FocusFields {
        case username, password
    }
    
    @FocusState private var focusedField: FocusFields?
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 15){
            ScrollView(showsIndicators: false){
                
                Text("Welkom!")
                  .font(.largeTitle).foregroundColor(Color.black)
                  .padding([.top, .bottom], 40)
                
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
            }
        }
    }
}

struct Register_Previews: PreviewProvider {
    static var previews: some View {
        Register()
    }
}
