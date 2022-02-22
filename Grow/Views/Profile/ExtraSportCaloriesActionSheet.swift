//
//  ExtraSportCaloriesActionSheet.swift
//  Grow
//
//  Created by Swen Rolink on 06/12/2021.
//

import SwiftUI

struct ExtraSportCaloriesActionSheet: View {
    
    @EnvironmentObject var userModel: UserDataModel
    @Binding var enableExtraCalorieSheet: Bool
    
    var body: some View {
        ZStack{
            GeometryReader { gr in
                VStack {
                    VStack {
                        Text("Percentage extra calorieën op een sportdag")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        let calorieBinding = Binding(
                            get: { self.userModel.user.extraCaloriePercentage ?? 0 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .ExtraTrainingCalories, to: $0)
                                    }
                                    catch{
                                        print("Oops")
                                    }
                                }
                        )
                        
                        Picker("Extra percentage calorieën", selection: calorieBinding) {
                            ForEach(0..<100) {
                                Text("+ \($0)%").tag($0)
                            }
                        }.pickerStyle(WheelPickerStyle())
                        
                    }.background(RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.white).shadow(radius: 1))
                    VStack {
                        Button(action: {
                            self.enableExtraCalorieSheet.toggle()
                        }) {
                            Text("Klaar").fontWeight(Font.Weight.bold)
                        }.padding()
                            .buttonStyle(SecondaryButtonStyle())

                    }
                }.position(x: gr.size.width / 2 ,y: gr.size.height - 200)
            }.edgesIgnoringSafeArea(.all)
        }.background(Color.black.opacity(0.6))
    }
}
