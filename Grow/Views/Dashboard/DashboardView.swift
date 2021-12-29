//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase
import HealthKit
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
    @State var bannerView = GADBannerView()

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
        
        NavigationView{
            VStack{
                List{
                    Section(header: Text(Date(), style: .date)){
                        ZStack{
                            HStack{
                                CircleView()
                                    .padding(.top, 20)
                                    .padding(.bottom, 20)
                                    VStack{
                                        HStack{
                                            ContentViewLinearKoolh()
                                            ContentViewLinearEiwit()
                                            }
                                        HStack{
                                                ContentViewLinearVet()
                                                ContentViewLinearVezel()
                                                }
                                        
                                            }.padding(.top, 10)
                                             .padding(.bottom, 20)
                                        }
                            NavigationLink(destination:FoodView()){}.isDetailLink(false).opacity(0)
                        }
                        //GoogleAddBanner()
                    }
                    if self.userModel.isNewMeasurementDay {
                        Section{
                            HStack{
                                NavigationLink(destination: NewMeasurementView(showMeasurementView: $showMeasurementView), isActive:$showMeasurementView){
                                        Image(systemName: "alarm").foregroundColor(.accentColor)
                                        Text("Tijd voor een nieuwe meting")
                                }
                            }
                        }
                    }
                    
                    Section(header:Text("Trainingen deze week")){
                        HStack{
                                TrainingCircle()
                            if let percentage = (self.userModel.workoutDonePercentage * 100).rounded(){
                                    let roundedPercentage = Int(round(percentage))
                                    Text("\(roundedPercentage) %")
                            }
                        }
                        if userModel.user.workoutOfTheDay != nil {
                            HStack{
                                NavigationLink(destination: WorkoutOfTheDayView(showWOD: $isWorkOutPresented, schema: userModel.user.schema!, routine: userModel.user.workoutOfTheDay!),isActive:$isWorkOutPresented) {
                                        HStack{
                                        Image(systemName: "bolt")
                                            .foregroundColor(.accentColor)

                                            Text("Start je training van vandaag").font(.subheadline).foregroundColor(Color.init("blackWhite"))
                                        }
                                }.isDetailLink(false)
                                }.padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))
                            }
                        
                        }
                    Section{
                        if bodyWeight != 0 {
                            HStack{
                                Text("Gewicht")
                                Spacer()
                                Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: self.bodyWeight)) kg").font(.headline)
                            }
                            if fatPercentage != 0 {
                                HStack{
                                    Text("Vet percentage")
                                    Spacer()
                                    Text("\(NumberHelper.roundNumbersMaxTwoDecimals(unit: self.fatPercentage)) %").font(.headline)
                                }
                            }
                        }
                    }
                }
            }
            .blur(radius: self.userModel.queryRunning ? 5 : 0)
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
            .onAppear(perform:{
                self.loadAndDisplayMostRecentWeight()
                self.loadAndDisplayMostRecentFatPercentage()
            })
        }
    }
}

struct TrainingCircle: View {
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(.accentColor)
                    
                
                Rectangle().frame(width: min(CGFloat(self.userModel.workoutDonePercentage)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(.accentColor)
                    .animation(Animation.linear(duration: 0.5), value: self.userModel.workoutDonePercentage)
            }
        }.cornerRadius(45.0).padding()
    }
}

struct CircleView: View {
    var body: some View {
    
        ZStack {
            VStack {
                ProgressBarCirle()
                    .frame(width: 125.0, height: 125.0)
                }
        }
    }
}

struct ProgressBarCirle: View {
    @EnvironmentObject var foodModel: FoodDataModel
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 5.0)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                if self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal <= 0.9 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.green)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(Animation.linear(duration: 0.5), value: self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)
                }
                else if self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal > 0.9 && self.foodModel.foodDiary.usersCalorieUsedPercentage.kcal < 0.95{
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.orange)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(Animation.linear(duration: 0.5), value: self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)
                }
                else if self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal > 0.95 && self.foodModel.foodDiary.usersCalorieUsedPercentage.kcal < 1.05{
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.green)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(Animation.linear(duration: 0.5), value: self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)
                }
                else if self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal > 1.05 && self.foodModel.foodDiary.usersCalorieUsedPercentage.kcal < 1.1{
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.orange)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(Animation.linear(duration: 0.5), value: self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)
                }
                else {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.red)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(Animation.linear(duration: 0.5), value: self.foodModel.todaysDiary.usersCalorieUsedPercentage.kcal)
                    
                }
                VStack{
                    Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.todaysDiary.usersCalorieLeftOver.kcal))
                    Text("Kcal over")
                }
            }
        }
    }

struct ProgressBarLinearDashboard: View {
    @Binding var value: Float
    @EnvironmentObject var userModel: UserDataModel
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                if value <= 0.90 {
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color.red)
                    .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 0.90 && value < 0.95 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 0.95 && value < 1.05 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 1.05 && value < 1.1 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.red)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
            }.cornerRadius(45.0)
            .offset(y: geometry.size.height/3.5)
        }
    }
}

struct FiberProgressBarLinearDashboard: View {
    @Binding var value: Float
    @EnvironmentObject var userModel: UserDataModel
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                if value <= 0.90 {
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color.red)
                    .animation(Animation.linear(duration: 0.5), value: value)
                }
                else if value > 0.9 && value < 0.95 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.orange)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
                else {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.green)
                        .animation(Animation.linear(duration: 0.5), value: value)
                }
            }.cornerRadius(45.0)
            .offset(y: geometry.size.height/3.5)
        }
    }
}

struct ContentViewLinearKoolh: View {
    @EnvironmentObject var foodModel: FoodDataModel

    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.todaysDiary.usersCalorieLeftOver.carbs)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                }
                Text("Koolh. over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearDashboard(value: $foodModel.todaysDiary.usersCalorieUsedPercentage.carbs).frame(height: 7.5)

        }
    }
}

struct ContentViewLinearEiwit: View {
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.todaysDiary.usersCalorieLeftOver.protein)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Eiwitten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearDashboard(value: $foodModel.todaysDiary.usersCalorieUsedPercentage.protein).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVet: View {
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.todaysDiary.usersCalorieLeftOver.fat)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vetten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearDashboard(value: $foodModel.todaysDiary.usersCalorieUsedPercentage.fat).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVezel: View {
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(NumberHelper.roundedNumbersFromDouble(unit:self.foodModel.todaysDiary.usersCalorieLeftOver.fiber)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vezels over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            FiberProgressBarLinearDashboard(value: $foodModel.todaysDiary.usersCalorieUsedPercentage.fiber).frame(height: 7.5)
            
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
