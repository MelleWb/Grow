//
//  MenuView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI

struct MenuView: View {
    var items = [["Dashboard", "dashboard"],["Training","dumbbell"],["Chat","chat"], ["Voeding","food"]]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
                HStack{
                    Image("menuImage")
                        .resizable()
                        .frame(width: 70, height: 75)
                        .overlay(Circle().stroke(Color.black, lineWidth:1))
                        .clipShape(Circle())
                        .shadow(radius: 10)
                    Text("Grow").font(.headline).foregroundColor(Color.init("textColor"))
                    
                }.padding(.init(top: 100, leading: 0, bottom: 12, trailing: 0))
            
            Divider()

            ForEach(0..<items.count) { i in
                MenuItem(item: items[i], id:i)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.init("background"))
        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        .edgesIgnoringSafeArea(.all)
    }
}

struct MenuItem:View {
    var item: [String]
    var id: Int
    
    var body: some View{
        return NavigationLink(
            destination: TrainingOverview()){
            
        HStack {
            Image(item[1])
                .resizable()
                .frame(width: 20, height: 25, alignment: .leading)
            Text(item[0])
                .foregroundColor(Color.init("textColor"))
                .font(.headline)
        }
        .padding(.top, 30)
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
