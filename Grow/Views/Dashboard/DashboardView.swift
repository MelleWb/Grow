//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import HealthKit
import FirebaseAuth
import GoogleMobileAds

struct TabBarView: View {
    
    @StateObject var userModel = UserDataModel()
    @StateObject var trainingModel = TrainingDataModel()
    @StateObject var statisticsModel = StatisticsDataModel()
    @StateObject var foodModel = FoodDataModel()
    
    var body: some View {
        TabView {
            Dashboard()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }

            TrainingDashboardView()
                .tabItem {
                    Label("Training", systemImage: "bolt")
                }
            
            MeasurementOverview()
                .tabItem{
                    Label("Progressie", systemImage: "chart.bar.xaxis")
                }
                    
            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gear")
                }
        }
        .environmentObject(userModel)
        .environmentObject(trainingModel)
        .environmentObject(statisticsModel)
        .environmentObject(foodModel)
    }
}

struct Dashboard: View{
    
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    @State var showProfileView: Bool = false
    @State private var isWorkOutPresented = false
    @State var showMeasurementView: Bool = false
    @State var bodyWeight: Double = 0
    @State var fatPercentage: Double = 0

    private var roundedWorkoutPercentage: Int {
        Int((self.userModel.workoutDonePercentage * 100).rounded())
    }

    private func loadAndDisplayMostRecentWeight() {
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
          print("Body Mass Sample Type is no longer available in HealthKit")
          return
        }
            
        HealthKitDataStore.getMostRecentSample(for: weightSampleType) { (sample, error) in
              
          guard let sample = sample else {
                
            if error != nil {
              print("An Error occured")
            }
            return
          }
              
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            bodyWeight = weightInKilograms
        }
    }
    
    private func loadAndDisplayMostRecentFatPercentage() {
        guard let fatPercentageSampleType = HKSampleType.quantityType(forIdentifier: .bodyFatPercentage) else {
          print("Body Mass Sample Type is no longer available in HealthKit")
          return
        }
            
        HealthKitDataStore.getMostRecentSample(for: fatPercentageSampleType) { (sample, error) in
              
          guard let sample = sample else {
                
            if error != nil {
              print("An Error occured")
            }
            return
          }
              
            let fatPercentageDouble = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            self.fatPercentage = fatPercentageDouble
        }
    }
    
    var body: some View {
        
        NavigationStack{
            VStack{
                List{
                    DashboardNutritionSection()

                    if self.userModel.isNewMeasurementDay {
                        DashboardMeasurementSection(showMeasurementView: $showMeasurementView)
                    }

                    DashboardTrainingSection(
                        roundedWorkoutPercentage: roundedWorkoutPercentage,
                        isWorkOutPresented: $isWorkOutPresented
                    )

                    DashboardBodyMetricsSection(
                        bodyWeight: bodyWeight,
                        fatPercentage: fatPercentage
                    )
                }
            }
            .overlay(
                ProgressView("Loading...")
                    .padding()
                    .background(Color.secondary.colorInvert())
                    .foregroundColor(Color.primary)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .frame(width: 500, height: 250, alignment: .center)
                    .opacity(self.userModel.queryRunning ? 1 : 0)
                )
            .disabled(self.userModel.queryRunning)
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text("Dashboard"))
            .navigationDestination(isPresented: $showMeasurementView) {
                NewMeasurementView(showMeasurementView: $showMeasurementView)
            }
            .navigationDestination(isPresented: $isWorkOutPresented) {
                if let routine = self.userModel.user.workoutOfTheDay {
                    WorkoutOfTheDayView(showWOD: $isWorkOutPresented, routine: routine)
                } else {
                    EmptyView()
                }
            }
            .onAppear(perform:{
                
                //Compare dates, if different (after 12.00AM), load new day
                let isSameDay:Bool = self.userModel.isSameDay(date1: self.userModel.currentDate, date2: Date())
                
                if !isSameDay {
                    self.userModel.fetchUser(uid: Auth.auth().currentUser!.uid){
                        self.foodModel.initiateFoodModel()
                        self.trainingModel.initiateTrainingModel()
                        self.statisticsModel.initiateStatistics()
                        self.userModel.currentDate = Date()
                    }
                }
                
                self.loadAndDisplayMostRecentWeight()
                self.loadAndDisplayMostRecentFatPercentage()
            })
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
