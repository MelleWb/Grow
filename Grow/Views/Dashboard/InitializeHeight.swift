//
//  InitializeHeight.swift
//  Grow
//
//  Created by Melle Wittebrood on 21/01/2022.
//

import SwiftUI

struct InitializeHeight: View {
        
    @EnvironmentObject var userModel: UserDataModel
        
    @Binding var enableHeightSheet: Bool
    @Binding var heigth: Int
        
        var body: some View {
                GeometryReader { gr in
                    VStack {
                        VStack {
                            Text("Lengte in cm")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 10)
                            
                            Picker("Lengte in cm", selection: $heigth) {
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

