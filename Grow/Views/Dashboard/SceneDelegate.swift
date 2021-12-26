//
//  SceneDelegate.swift
//  Grow
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import Firebase

struct SceneDelegate : View{

    @State var ViewToDisplay: Views?
    
    enum Views{
        case dashboard, login
    }
    
    func setViewToDisplay(view: Views){
        self.ViewToDisplay = view
    }
    
    var body: some View{
        VStack{
            if ViewToDisplay == .dashboard {
                TabBarView()
                } else {
                    Login()
                }
        }.onAppear(perform: {
            Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                let pushManager = PushNotificationManager(userID: user?.uid ?? "test")
                    pushManager.registerForPushNotifications()
                setViewToDisplay(view: .dashboard)
            } else {
                setViewToDisplay(view: .login)
                }
            }
        })
        .environment(\.locale, Locale.init(identifier: "nl_NL"))
    }
}
