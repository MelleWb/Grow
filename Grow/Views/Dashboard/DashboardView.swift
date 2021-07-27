//
//  ContentView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI
import Firebase

extension UITabBarController {
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let standardAppearance = UITabBarAppearance()
        
        standardAppearance.stackedLayoutAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.red]
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.red]
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.red]
        
        tabBar.standardAppearance = standardAppearance
    }
}

struct TabBarView: View {
    var body: some View {
        TabView {
                DashboardView()
                       .tabItem {
                        Label("Dashboard", systemImage: "gauge").foregroundColor(Color.init("textColor"))
                       }

                   ExerciseOverview()
                       .tabItem {
                        Label("Oefeningen", systemImage: "square.and.pencil").foregroundColor(Color.init("textColor"))
                       }
            
                    TrainingOverview()
                        .tabItem {
                            Label("Schemas", systemImage: "list.dash").foregroundColor(Color.init("textColor"))
                        }
        }
    }
}

struct DashboardView: View {

    
    @StateObject var userModel = UserDataModel()
    
    @State var showMenu = false
    @State var showProfileSheetView = false
    @State var viewToShow: String = "LandingPageView"
    
    var body: some View {
        
        let tap = TapGesture()
            .onEnded {
                withAnimation{
                self.showMenu = false
                }
            }

            NavigationView {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    MainView(viewToShow: $viewToShow, showMenu: self.$showMenu)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showMenu ? geometry.size.width/1.25 : 0)
                        .disabled(self.showMenu ? true : false)
                    if self.showMenu {
                        MenuView()
                            .frame(width: geometry.size.width/1.25)
                            .transition(.move(edge: .leading))
                        }
                }
                .gesture(tap)
        }
        .environmentObject(userModel)
        .onAppear(perform:{
            userModel.fetchUser(uid: Auth.auth().currentUser!.uid)
            
            let pushManager = PushNotificationManager(userID: Auth.auth().currentUser!.uid)
            pushManager.registerForPushNotifications()
        })
        .navigationBarTitle("Dashboard", displayMode: .inline)
        .navigationBarItems(leading: (
                            Button(action: {
                                withAnimation {
                                    self.showMenu.toggle()
                                }
                            }) {
                                Image(systemName:"line.horizontal.3")
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .foregroundColor(Color.init("textColor"))
                            }
                        ),
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

struct LandingPageView: View {
    @EnvironmentObject var userModel: UserDataModel
    
    @State var frame: CGSize = .zero
    var coachPicture: UIImage?
    
    var body: some View {
        //Determine the size of the view
        GeometryReader { (geometry) in
                        self.makeView(geometry)
        }
        VStack {
            VStack{
                Text(userModel.user.firstName ?? "").font(.headline).foregroundColor(.white).frame(width: frame.width, height: frame.height, alignment: .bottom)
            }.frame(width: frame.width, height: frame.height/4, alignment: .top)
            .background(
                    Image("barbellImage")
                    .resizable()
                    .shadow(radius: 10)
                    .scaledToFill()
                )
            
            HStack{
                List{
                    HStack{
                        
                        Image(uiImage: (userModel.userImages.coachImage?.image ?? UIImage(named: "loadingImageCircle"))!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 75, height: 75, alignment: .leading)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 20))
                            
                        VStack{
                            Text("Coach").padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0)).foregroundColor(Color.init("textColor")).font(.largeTitle)
                            //Text("Melle").padding(.init(top: 10, leading: 0, bottom: 10, trailing: 0)).foregroundColor(Color.init("textColor")).font(.headline)
                            
                        }
                        Spacer()
                    }.padding(.init(top: 5, leading: 5, bottom: 5, trailing: 5))
                    HStack{
                        VStack{
                            Text("Kcal")
                            Text(String(userModel.user.kcal ?? 0))
                        }
                        VStack{
                            Text("Carbs")
                            Text(String(userModel.user.carbs ?? 0))
                        }
                        VStack{
                            Text("Protein")
                            Text(String(userModel.user.protein ?? 0))
                        }
                        VStack{
                            Text("Fats")
                            Text(String(userModel.user.fat ?? 0))
                        }
                        VStack{
                            Text("Fibers")
                            Text(String(userModel.user.fiber ?? 0))
                        }
                    }
                    HStack{
                        NavigationLink(destination: ExerciseOverview(searchText: "")){
                            //
                        }
                    }
                }
                
            }
            
        }.padding(.init(top: 12, leading: 0, bottom: 0, trailing: 0)).contentShape(Rectangle())
    }
    
    func makeView(_ geometry: GeometryProxy) -> some View {
            DispatchQueue.main.async { self.frame = geometry.size }

        return Text("").frame(width:geometry.size.width)
        }
}

struct MainView: View {
    @Binding var viewToShow: String
    var view: AnyView?
    @Binding var showMenu: Bool
    @EnvironmentObject var userModel: UserDataModel
    
    @State var frame: CGSize = .zero
    var coachPicture: UIImage?
    
    var body: some View {
        if viewToShow == "LandingPageView"{
            LandingPageView()
        }
        else if viewToShow == "Schemas"{
            TrainingOverview()
        }
    }
}
