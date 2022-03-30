//
//  NPActionSheet.swift
//  Grow
//
//  Created by Swen Rolink on 04/12/2021.
//

import SwiftUI

struct WeightActionSheet: View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    @Binding var enableWeightSheet: Bool
    
    var body: some View {
        ZStack{
            GeometryReader { gr in
                VStack {
                    VStack {
                        Text("Gewicht in kg")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        let weightBinding = Binding(
                            get: { self.userModel.user.weight ?? 1 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .Weight, to: $0)
                                    }
                                    catch{
                                        print("Oops")
                                    }
                                }
                        )
                        
                        Picker("Gewicht", selection: weightBinding) {
                            ForEach(50..<200) {
                                Text("\($0) kg").tag($0)
                            }
                        }.pickerStyle(WheelPickerStyle())
                        
                    }.background(RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.init("textField")).shadow(radius: 1))
                    VStack {
                        Button(action: {
                            self.enableWeightSheet.toggle()
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
