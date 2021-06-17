//
//  ContentView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI

struct HomeView: View {
    
    @State var trainingOverview: overview = JsonParser().trainingOverview

    var body: some View {
            NavigationView {
                List {
                    ForEach(trainingOverview.days, id: \.self) {
                            days in DayRow(days: days)
                    }.onMove(perform: { indexSet, index in
                        self.trainingOverview.days.move(fromOffsets: indexSet, toOffset: index)
                        
                    })
                    }	.navigationBarTitle(Text(verbatim: "Schema van " + trainingOverview.trainee))
                .navigationBarItems(trailing: EditButton())
            }
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
                    //.overlay(Circle().stroke(Color.black, lineWidth:1))
                    .frame(width:50, height:50)
                    .shadow(radius: 10)
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
