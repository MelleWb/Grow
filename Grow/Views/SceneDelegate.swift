//
//  SceneDelegate.swift
//  Grow
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import Firebase

struct SceneDelegate : View{

    @ObservedObject var userSettings = UserSettings()
    
    @State var ViewToDisplay:String = ""
    
    func setViewToDisplay(view: String){
        self.ViewToDisplay = view
    }
    
    var body: some View{
        VStack{
            
            if ViewToDisplay == "Dashboard" {
                DashboardView()
                } else {
                    LoginView()
                }
        }.onAppear(perform: {
            Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                setViewToDisplay(view: "Dashboard")
            } else {
                setViewToDisplay(view: "Login")
                }
            }
        })
    }
}

struct SceneDelegate_Previews: PreviewProvider {
    static var previews: some View {
        SceneDelegate()
    }
}
