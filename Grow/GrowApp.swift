//
//  GrowApp.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI
import Firebase

@main

struct GrowApp: App {
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
            FirebaseApp.configure()
        }
    
    var body: some Scene {
    
        WindowGroup {
            SceneDelegate()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
}
