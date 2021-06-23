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
    
    init() {
            FirebaseApp.configure()
        }
    
    var body: some Scene {
    
        WindowGroup {
            SceneDelegate()
        }
    }
}


