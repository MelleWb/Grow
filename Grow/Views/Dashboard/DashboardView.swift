//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase

struct TabBarView: View {
    
    @ObservedObject var userModel = UserDataModel()
    @ObservedObject var trainingModel = TrainingDataModel()
    
    init(){
        self.userModel.fetchUser(uid: Auth.auth().currentUser!.uid)
    }
    
    var body: some View {
        TabView {
            Dashboard()
                .environmentObject(userModel)
                .environmentObject(trainingModel)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }

            TrainingDashboardView()
                .environmentObject(userModel)
                .environmentObject(trainingModel)
                .tabItem {
                    Label("Training", systemImage: "bolt")
                }
                    
            ChatView().environmentObject(userModel)
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
        }.accentColor(Color.init("textColor"))
    }
}

struct Dashboard: View{
    @EnvironmentObject var userModel : UserDataModel
    @EnvironmentObject var trainingModel: TrainingDataModel
    @ObservedObject var foodModel = FoodDataModel()
    @State var showProfileSheetView: Bool = false
    
    var body: some View {
        
        NavigationView{
            List{
                Section{
                    ZStack{
                        HStack{
                            CircleView()
                                .environmentObject(userModel)
                                .environmentObject(foodModel)
                                .padding(.top, 20)
                                .padding(.bottom, 20)
                                VStack{
                                    HStack{
                                        ContentViewLinearKoolh().environmentObject(userModel).environmentObject(foodModel)
                                    ContentViewLinearEiwit().environmentObject(userModel).environmentObject(foodModel)
                                        }
                                        HStack{
                                            ContentViewLinearVet().environmentObject(userModel).environmentObject(foodModel)
                                            ContentViewLinearVezel().environmentObject(userModel).environmentObject(foodModel)
                                            }
                                        }.padding(.top, 10)
                                         .padding(.bottom, 20)
                                    }
                        NavigationLink(destination:FoodView()){}.hidden()
                    }
                }
                Section(header:Text("Trainingen van deze week")){
                    HStack{
                        ForEach(userModel.user.weekPlan!, id:\.self){  day in
                            if day.isTrainingDay ?? true {
                                Image(systemName:"star.fill")
                                    .frame(width: 50, height: 50, alignment: .leading)
                                    .foregroundColor(Color.init("textColor"))
                            }
                        }
                    }.padding()
                    if userModel.user.workoutOfTheDay != nil {
                        HStack{
                            ZStack{
                                Button("") {}
                                NavigationLink(destination: WorkoutOfTheDayView(schema: userModel.user.schema!, routine: userModel.user.workoutOfTheDay!).environmentObject(trainingModel)){
                                    Image("upper")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30, alignment: .leading)
                                        .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))

                                    VStack(alignment: .leading){
                                        Text("Start je training van vandaag").font(.subheadline).bold()
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .onAppear(perform:{
                self.foodModel.getTodaysIntake(for: userModel)
            })
            .environmentObject(userModel)
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
                    UpdateProfile(showProfileSheetView: $showProfileSheetView).environmentObject(userModel)
                    }
                }
            }
        }

struct CircleView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
    
        ZStack {
            VStack {
                ProgressBarCirle(progress: self.$foodModel.userIntakeLeftOvers.kcal)
                    .frame(width: 125.0, height: 125.0)
                }
        }
    }
}

struct ProgressBarCirle: View {
    @Binding var progress: Float
    @EnvironmentObject var userModel: UserDataModel
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 5.0)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                if self.progress <= 0.8 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.green)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                }
                else if self.progress > 0.8 && self.progress < 1{
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.orange)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
                }
                else {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.red)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                    
                }
                VStack{
                    Text(String(userModel.user.kcal ?? 0))
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
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(userModel.user.carbs ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                }
                Text("Koolh. over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $foodModel.userIntakeLeftOvers.carbs).frame(height: 7.5)

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
                    Text(String(userModel.user.protein ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Eiwitten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $foodModel.userIntakeLeftOvers.protein).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVet: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(userModel.user.fat ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vetten over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $foodModel.userIntakeLeftOvers.fat).frame(height: 7.5)
        }
    }
}

struct ContentViewLinearVezel: View {
    @EnvironmentObject var userModel: UserDataModel
    @EnvironmentObject var foodModel: FoodDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(userModel.user.fiber ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vezels over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearFood(value: $foodModel.userIntakeLeftOvers.fiber).frame(height: 7.5)
            
        }
    }
}

