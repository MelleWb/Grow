//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase

struct TabBarView: View {
    var body: some View {
        TabView {
                    Dashboard()
                       .tabItem {
                        Label("Dashboard", systemImage: "gauge")
                       }

                   ExerciseOverview()
                       .tabItem {
                        Label("Oefeningen", systemImage: "square.and.pencil")
                       }
            
                    TrainingOverview()
                        .tabItem {
                            Label("Schemas", systemImage: "list.dash")
                        }
        }.accentColor(Color.init("textColor"))
    }
}

struct Dashboard: View{
    @StateObject var userModel = UserDataModel()
    @State var showProfileSheetView: Bool = false
    
    var body: some View {
        NavigationView{
            List{
                Section{
                    HStack{
                        CircleView().environmentObject(userModel)
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
                }
                Section {
                    Spacer()
                        HStack{
                            ZStack{
                                Button("") {}
                                    NavigationLink(destination: FoodView()){
                                    Image("food")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30, alignment: .leading)
                                        .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))

                                    VStack(alignment: .leading){
                                            Text("Voeding")
                                            Text("Vul je voeding in")
                                        }
                                    }
                                }
                            }
                
                    HStack{
                        ZStack{
                            Button("") {}
                                NavigationLink(destination: FoodView()){
                                Image("upper")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30, alignment: .leading)
                                    //.clipShape(Circle())
                                    //.shadow(radius: 10)
                                    .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))

                                VStack(alignment: .leading){
                                        Text("Training")
                                        Text("Start je training")
                                    }
                                }
                            }
                    }
                }
                    }.listStyle(InsetGroupedListStyle())
                            .environmentObject(userModel)
                            .onAppear(perform:{
                            userModel.fetchUser(uid: Auth.auth().currentUser!.uid)
                            })
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
                                UpdateProfile(showProfileSheetView: $showProfileSheetView, userModel: userModel, firstName: userModel.user.firstName ?? "", lastName: userModel.user.lastName ?? "", dateOfBirth: userModel.user.dateOfBirth ?? DateHelper.from(year: 1990, month: 1, day: 1), gender: userModel.user.gender ?? 0, weight: userModel.user.weight ?? 0, height: userModel.user.height ?? 0, plan: userModel.user.plan ?? 1, kcal: userModel.user.kcal ?? 0, palOption: userModel.user.pal ?? 0, originalImage: userModel.userImages.userImage?.image)
                                }
                }
            }
        }

struct CircleView: View {
    @ObservedObject var foodModel = FoodDataModel()
    @EnvironmentObject var userModel: UserDataModel

    init(){
        self.foodModel.getTodaysIntake(usersKcalBudget: 3034)
    }
    
    
    
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

struct ProgressBarLinearKoolh: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.gray))
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}

struct ContentViewLinearKoolh: View {
    @State var progressValue: Float = 0.0
    @EnvironmentObject var userModel: UserDataModel

    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(userModel.user.carbs ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                }
                Text("Koolh. over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearKoolh(value: $progressValue).frame(height: 7.5)

        }
    }
}

struct ProgressBarLinearEiwit: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.gray))
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}

struct ContentViewLinearEiwit: View {
    @State var progressValue: Float = 0.0
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
            ProgressBarLinearEiwit(value: $progressValue).frame(height: 7.5)
        }
    }
    
    func startProgressBar() {
        for _ in 0...80 {
            self.progressValue += 0.015
        }
    }
    
    func resetProgressBar() {
        self.progressValue = 0.0
    }
}

struct ProgressBarLinearVet: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.gray))
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}

struct ContentViewLinearVet: View {
    @State var progressValue: Float = 0.0
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
            ProgressBarLinearVet(value: $progressValue).frame(height: 7.5)
        }
    }
}

struct ProgressBarLinearVezel: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.gray))
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.gray))
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}

struct ContentViewLinearVezel: View {
    @State var progressValue: Float = 0.0
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text(String(userModel.user.fiber ?? 0)).font(.subheadline).bold()
                    Text("g").font(.subheadline).bold()
                    }
                Text("Vezels over").font(.subheadline).foregroundColor(Color.gray).fixedSize(horizontal: true, vertical: false)
                }
            ProgressBarLinearVezel(value: $progressValue).frame(height: 7.5)
            
        }
    }
    
    func startProgressBar() {
        for _ in 0...80 {
            self.progressValue += 0.015
        }
    }
    
    func resetProgressBar() {
        self.progressValue = 0.0
    }
}

