//
//  HeightActionSheet.swift
//  Grow
//
//  Created by Swen Rolink on 05/12/2021.
//

import SwiftUI

struct HeightActionSheet: View {
    
    @EnvironmentObject var userModel: UserDataModel
    
    @Binding var enableHeightSheet: Bool
    
    var body: some View {
            GeometryReader { gr in
                VStack {
                    VStack {
                        Text("Lengte in cm")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        let heightBinding = Binding(
                            get: { self.userModel.user.height ?? 1 },
                            set: {
                                do {
                                    try self.userModel.updateUserElements(for: .Height, to: $0)
                                    }
                                    catch{
                                        print("Oops")
                                    }
                                }
                        )
                        
                        Picker("Lengte in cm", selection: heightBinding) {
                            ForEach(100..<250) {
                                Text("\($0) cm").tag($0)
                            }
                        }.pickerStyle(WheelPickerStyle())
                        
                    }.background(RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.white).shadow(radius: 1))
                    VStack {
                        Button(action: {
                            self.enableHeightSheet.toggle()
                        }) {
                            Text("Klaar").fontWeight(Font.Weight.bold)
                        }.padding()
                            .buttonStyle(SecondaryButtonStyle())

                    }
                }.position(x: gr.size.width / 2 ,y: gr.size.height - 200)
            }
    }
}
