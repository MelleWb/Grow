//
//  ContentView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI

struct HomeView: View {
    
    @State var showMenu = false
    
    var body: some View {
        
        let drag = DragGesture()
            .onEnded {
                if $0.translation.width < -100 {
                    withAnimation {
                        self.showMenu = false
                    }
                }
            }

        return NavigationView {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    MainView(showMenu: self.$showMenu)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showMenu ? geometry.size.width/2 : 0)
                        .disabled(self.showMenu ? true : false)
                    if self.showMenu {
                        MenuView()
                            .frame(width: geometry.size.width/2)
                            .transition(.move(edge: .leading))
                        }
                }
                .gesture(drag)
        }
        .navigationBarTitle("Dashboard", displayMode: .inline)
        .navigationBarItems(leading: (
                            Button(action: {
                                withAnimation {
                                    self.showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "line.horizontal.3").foregroundColor(Color .black)
                            }
                        ))
        }
    }
}


struct MainView: View {
    @Binding var showMenu: Bool
    var body: some View {
    
        VStack {
            Image("dashboard").resizable().frame(width: 70, height: 75)
            Spacer().frame(height: 50)
            Text("Melle Wittebrood")
            HStack{
                List{
                    HStack{
                        Image("dumbbell")
                            .resizable()
                            .frame(width: 40, height: 45, alignment: .leading)
                    Text("Training").padding(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }
                    HStack{
                        Image("food")
                            .resizable()
                            .frame(width: 40, height: 45, alignment: .leading)
                    Text("Voeding").padding(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }
                }
            }
        }.padding(.init(top: 12, leading: 0, bottom: 0, trailing: 0))
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


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
        }
    }
}
