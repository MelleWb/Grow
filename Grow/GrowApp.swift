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
import WatchConnectivity

@main

struct GrowApp: App {
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        _ = WatchFoodSummarySync.shared
        
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

#if os(iOS)
final class WatchFoodSummarySync: NSObject, WCSessionDelegate {
    static let shared = WatchFoodSummarySync()

    private var pendingContext: [String: Any]?
    private let requestMessageKey = "requestFoodSummary"

    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func push(diary: FoodDiary) {
        pendingContext = buildContext(from: diary)
        sendContextIfPossible()
    }

    private func buildContext(from diary: FoodDiary) -> [String: Any] {
        [
            "updatedAt": Date().timeIntervalSince1970,
            "remainingKcal": diary.usersCalorieLeftOver.kcal,
            "remainingCarbs": diary.usersCalorieLeftOver.carbs,
            "remainingFat": diary.usersCalorieLeftOver.fat,
            "remainingProtein": diary.usersCalorieLeftOver.protein,
            "remainingFiber": diary.usersCalorieLeftOver.fiber,
            "budgetKcal": diary.usersCalorieBudget.kcal,
            "budgetCarbs": diary.usersCalorieBudget.carbs,
            "budgetFat": diary.usersCalorieBudget.fat,
            "budgetProtein": diary.usersCalorieBudget.protein,
            "budgetFiber": diary.usersCalorieBudget.fiber,
            "usedRatioKcal": Double(diary.usersCalorieUsedPercentage.kcal),
            "usedRatioCarbs": Double(diary.usersCalorieUsedPercentage.carbs),
            "usedRatioFat": Double(diary.usersCalorieUsedPercentage.fat),
            "usedRatioProtein": Double(diary.usersCalorieUsedPercentage.protein),
            "usedRatioFiber": Double(diary.usersCalorieUsedPercentage.fiber)
        ]
    }

    private func sendContextIfPossible() {
        guard let pendingContext, WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        guard session.activationState == .activated else {
            return
        }

        do {
            try session.updateApplicationContext(pendingContext)
        } catch {
            print("Failed to sync food summary to watch: \(error)")
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("Watch connectivity activation failed: \(error)")
        }
        sendContextIfPossible()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        guard message[requestMessageKey] as? Bool == true else {
            replyHandler([:])
            return
        }

        replyHandler(pendingContext ?? [:])
    }
}
#endif
