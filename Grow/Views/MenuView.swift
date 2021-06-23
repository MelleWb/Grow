//
//  MenuView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI

struct MenuView: View {
    
    
    var views = [aView(view: AnyView(UpdateProfile(displayName: "")), label: "Profiel", image: ""),
                 aView(view: AnyView(TrainingOverview()), label: "Training", image: "dumbbell")]
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
                HStack{
                    Image("menuImage")
                        .resizable()
                        .frame(width: 70, height: 75)
                        .shadow(radius: 10)
                    Text("Grow").font(.headline).foregroundColor(Color.init("blackWhite"))
                    
                }.padding(.init(top: 80, leading: 0, bottom: 7, trailing: 0))
            
            Divider()

            ForEach(views, id: \.id) { view in
                //MenuItem(view: view.view, label: view.label, image: view.image)
                NavigationLink( destination: view.view) {
                        HStack {
                            
                            Image(view.image)
                                .resizable()
                                .frame(width: 20, height: 25, alignment: .leading)

                            Text(view.label)
                                .foregroundColor(Color.init("textColor"))
                                .font(.headline)
                        }
                        .padding(.top, 30)
                    }
                
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


struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
