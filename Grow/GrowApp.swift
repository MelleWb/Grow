//
//  GrowApp.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI
import UIKit.UIGestureRecognizerSubclass
import FirebaseCore
import GoogleMobileAds

@main

struct GrowApp: App {
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        // Initialize the Google Mobile Ads SDK.
        MobileAds.shared.start(completionHandler: nil)
        
            HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
                  
              guard authorized else {
                    
                let baseMessage = "HealthKit Authorization Failed"
                    
                    if let error = error {
                      print("\(baseMessage). Reason: \(error.localizedDescription)")
                    } else {
                      print(baseMessage)
                    }
                        
                    return
                  }
                print("HealthKit Successfully Authorized.")
                }
            }
        
    var body: some Scene {
    
        WindowGroup {
            SceneDelegate()
                .accentColor(Color.init("AccentColor"))
        }
    }
}

//class AppDelegate: NSObject, UIApplicationDelegate {
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        return true
//    }
//}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
