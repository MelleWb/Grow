//
//  TestDashboardView.swift
//  Grow
//
//  Created by Melle Wittebrood on 27/07/2021.
//

import SwiftUI
import Firebase

struct TestDashboard: View{
    @StateObject var userModel = UserDataModel()
    
    var body: some View {
List{
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
    
        Spacer()
            HStack{
                ZStack{
                    Button("") {}
                        NavigationLink(destination: FoodView()){
                        Image("food")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30, alignment: .leading)
                            //.clipShape(Circle())
                            //.shadow(radius: 10)
                            .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 20))

                        VStack(alignment: .leading){
                                Text("Voeding")
                                Text("Vul je voeding in")
                            }
                        }
                    }
                }
    
    Spacer()
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
                .environmentObject(userModel)
                .onAppear(perform:{
                userModel.fetchUser(uid: Auth.auth().currentUser!.uid)
                })
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
//            Color.yellow
//                .opacity(0.1)
//                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressBarCirle(progress: self.$foodModel.userIntakeLeftOvers.kcal)
                    .frame(width: 125.0, height: 125.0)
//                Button(action: {
//                    self.incrementProgress()
//                }) {
//                    HStack {
//                        Image(systemName: "plus.rectangle.fill")
//                        Text("Increment")
//                    }
//                    .padding(15.0)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 15.0)
//                            .stroke(lineWidth: 2.0)
//                    )
//                }
//                Spacer()
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
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
//                Text(String(format: "%.0f %%", min(self.progress, 1.0)*100.0))
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
                    Text(String(userModel.user.carbs ?? 0))
                    Text("g")
                }
                Text("Koolh. over")
                }
            ProgressBarLinearKoolh(value: $progressValue).frame(height: 7.5)
            
//            Button(action: {
//                self.startProgressBar()
//            }) {
//                Text("Start Progress")
//            }.padding()
//
//            Button(action: {
//                self.resetProgressBar()
//            }) {
//                Text("Reset")
//            }
            
//            Spacer()
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
                    Text(String(userModel.user.protein ?? 0))
                    Text("g")
                    }
                Text("Eiwitten over")
                }
            ProgressBarLinearEiwit(value: $progressValue).frame(height: 7.5)
            
//            Button(action: {
//                self.startProgressBar()
//            }) {
//                Text("Start Progress")
//            }.padding()
//
//            Button(action: {
//                self.resetProgressBar()
//            }) {
//                Text("Reset")
//            }
            
//            Spacer()
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
                    Text(String(userModel.user.fat ?? 0))
                    Text("g")
                    }
                Text("Vetten over")
                }
            ProgressBarLinearVet(value: $progressValue).frame(height: 7.5)
            
//            Button(action: {
//                self.startProgressBar()
//            }) {
//                Text("Start Progress")
//            }.padding()
//
//            Button(action: {
//                self.resetProgressBar()
//            }) {
//                Text("Reset")
//            }
            
//            Spacer()
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
                    Text(String(userModel.user.fiber ?? 0))
                    Text("g")
                    }
                Text("Vezels over")
                }
            ProgressBarLinearVezel(value: $progressValue).frame(height: 7.5)
            
//            Button(action: {
//                self.startProgressBar()
//            }) {
//                Text("Start Progress")
//            }.padding()
//
//            Button(action: {
//                self.resetProgressBar()
//            }) {
//                Text("Reset")
//            }
            
//            Spacer()
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

