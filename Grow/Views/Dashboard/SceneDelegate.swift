//
//  SceneDelegate.swift
//  Grow
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import FirebaseAuth

struct SceneDelegate : View{

    @State var ViewToDisplay: Views?
    @State private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    enum Views{
        case dashboard, login
    }
    
    var body: some View{
        VStack{
            if ViewToDisplay == .dashboard {
                TabBarView()
                } else {
                    Login()
                }
        }.onAppear(perform: {
            authStateListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            if let user {
                let pushManager = PushNotificationManager(userID: user.uid)
                    pushManager.registerForPushNotifications()
                ViewToDisplay = .dashboard
            } else {
                ViewToDisplay = .login
                }
            }
        })
        .onDisappear {
            if let authStateListenerHandle {
                Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
                self.authStateListenerHandle = nil
            }
        }
        .environment(\.locale, Locale.init(identifier: "nl_NL"))
    }
}
