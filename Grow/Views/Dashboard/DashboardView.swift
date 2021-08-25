//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase

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
                    
            ChatView().environmentObject(userModel)
                .tabItem {
                    Label("Chat", systemImage: "message")
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
    @State var showProfileSheetView: Bool = false
    @State var showWorkoutView: Bool = false
    
    var body: some View {
        
        ProgressIndicator(isShowing: self.$userModel.queryRunning, loadingText: "Profiel laden", content:{
            
        NavigationView{
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
                        NavigationLink(destination:FoodView()){}.hidden()
                    }
                }
                Section(header:Text("Trainingen deze week")){
                    HStack{
                        TrainingCircle()
                        let percentage = (self.userModel.workoutDonePercentage * 100).rounded()
                        let roundedPercentage = Int(round(percentage))
                        Text("\(roundedPercentage) %")
                    }
                    if userModel.user.workoutOfTheDay != nil {
                        HStack{
                            ZStack{
                                Button("") {}
                                NavigationLink(destination: WorkoutOfTheDayView(schema: userModel.user.schema!, routine: userModel.user.workoutOfTheDay!, showWorkoutView: $showWorkoutView), isActive: $showWorkoutView){
                                    Image(systemName: "bolt")
                                        .foregroundColor(.accentColor)
                                        .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))

                                    VStack(alignment: .leading){
                                        Text("Start je training van vandaag").font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text("Dashboard"))
            .navigationBarItems(
                trailing: Button(action: {
                    withAnimation {
                        self.showProfileSheetView.toggle()
                    }
                }) {
                    Image(uiImage: (userModel.userImages.userImage?.image ?? UIImage(named: "loadingImageCircle"))!)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 25, height: 25, alignment: .center)
                }).sheet(isPresented: $showProfileSheetView) {
                    UpdateProfile(showProfileSheetView: $showProfileSheetView)
                    }
                }
            }
        )}
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
                    .animation(.linear)
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
    @EnvironmentObject var userModel: UserDataModel
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 5.0)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                if self.userModel.userIntakeLeftOvers.kcal <= 0.8 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.userModel.userIntakeLeftOvers.kcal, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.green)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                }
                else if self.userModel.userIntakeLeftOvers.kcal > 0.8 && self.userModel.userIntakeLeftOvers.kcal < 1{
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.userModel.userIntakeLeftOvers.kcal, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.orange)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
                }
                else {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.userModel.userIntakeLeftOvers.kcal, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.red)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                    
                }
                VStack{
                    Text(String(self.userModel.userIntakeLeftOvers.kcal))
                    Text("Kcal over")
                }
            }
        }
    }

struct ProgressBarLinearFood: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                if value <= 0.8 {
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color.green)
                    .animation(.linear)
                }
                else if value > 0.8 && value < 1 {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.orange)
                        .animation(.linear)
                } else {
                    Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                        .foregroundColor(Color.red)
                        .animation(.linear)
                }
            }.cornerRadius(45.0)
        }
    }
}

struct ContentViewLinearKoolh: View {
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                }
                Text("Koolh. over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $userModel.userIntakeLeftOvers.carbs).frame(height: 7.5)

        }
    }
}

struct ContentViewLinearEiwit: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Eiwitten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $userModel.userIntakeLeftOvers.protein).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVet: View {
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vetten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $userModel.userIntakeLeftOvers.fat).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVezel: View {
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vezels over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $userModel.userIntakeLeftOvers.fiber).frame(height: 7.5)
            
        }
    }
}

