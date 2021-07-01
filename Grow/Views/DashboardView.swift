//
//  ContentView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI
import Firebase

struct DashboardView: View {

    
    @StateObject var userModel = UserDataModel()
    
    @State var showMenu = false
    @State var showProfileSheetView = false
    @State var isShowing: Bool = false
    
    var body: some View {
        
        let tap = TapGesture()
            .onEnded {
                withAnimation{
                self.showMenu = false
                }
            }

        return ProgressIndicator(isShowing: $isShowing) {
            NavigationView {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    MainView(showMenu: self.$showMenu)
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
        })
        .navigationBarTitle("Dashboard", displayMode: .inline)
        .navigationBarItems(leading: (
                            Button(action: {
                                withAnimation {
                                    self.showMenu.toggle()
                                }
                            }) {
                                Image("hamburgerMenu")
                                    .resizable()
                                    .frame(width: 25, height: 25, alignment: .center)
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
}


struct MainView: View {
    @Binding var showMenu: Bool
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
                        NavigationLink(destination: ExerciseOverview()){
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

struct TrainingOverview: View{
    
    @State var trainingOverview: overview = JsonParser().trainingOverview
    
    var body: some View {
            List {
                    ForEach(0..<trainingOverview.days.count) {
                        i in DayRow(days: trainingOverview.days[i])
                }.onMove(perform: { indexSet, index in
                    self.trainingOverview.days.move(fromOffsets: indexSet, toOffset: index)
                    
                })
                }    .navigationBarTitle(Text(verbatim: "Schema van " + trainingOverview.trainee))
            .navigationBarItems(trailing: EditButton())
    }

    
}


struct DayRow: View {
    
    let days: days
    
    var body: some View {

        let image = determineImage(type: days.type)
        
        return NavigationLink(
            destination: TrainingDetailView(name: days.type, image:image, exercises: days.exercises)){
        
            HStack{
                Image(image)
                    .resizable()
                    .frame(width:45, height:50)
                VStack (alignment: .leading) {
                    Text(days.type).font(.headline)
                }
            }.padding(.init(top: 12, leading: 0, bottom: 12, trailing: 0))
            
            
        }
    }
}
