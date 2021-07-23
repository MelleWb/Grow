//
//  MenuView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI
import Firebase

struct MenuView: View {
   
    var views = [aView(view: AnyView(TrainingOverview()), label: "Schemas", image: "dumbbell"),
                 aView(view: AnyView(ExerciseOverview()), label: "Oefeningen", image: "lower")
    ]
    var body: some View {
        
        VStack(alignment: .leading) {
            
                HStack{
                    Image("menuImage")
                        .resizable()
                        .frame(width: 70, height: 75)
                        .shadow(radius: 10)
                    Text("Grow").font(.headline).foregroundColor(Color.init("blackWhite")).padding(.init(30))
                    
                }.padding(.init(top: 80, leading: 0, bottom: 7, trailing: 0))
            
            Divider()

            ForEach(views, id: \.id) { view in
                //MenuItem(view: view.view, label: view.label, image: view.image)
                NavigationLink( destination: view.view) {
                        HStack {
                            
                            Image(view.image)
                                .resizable()
                                .frame(width: 25, height: 25, alignment: .leading)

                            Text(view.label)
                                .foregroundColor(Color.init("textColor"))
                                .font(.system(size: 20))
                        }
                        .padding(.top, 30)
                    }.navigationViewStyle(StackNavigationViewStyle())
                
            }
            Spacer()
            Button(action: {
                let firebaseAuth = Auth.auth()
               do {
                 try firebaseAuth.signOut()
               } catch let signOutError as NSError {
                 print ("Error signing out: %@", signOutError)
               }
            })
            {
                Text("Logout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 60, alignment: .center)
                    .background(Color.init("buttonColor"))
                    .cornerRadius(15.0)
            }
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
