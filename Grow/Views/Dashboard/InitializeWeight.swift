//
//  InitializeWeight.swift
//  Grow
//
//  Created by Melle Wittebrood on 21/01/2022.
//

import SwiftUI

struct InitializeWeight: View {

    @EnvironmentObject var userModel: UserDataModel

    @Binding var enableWeightSheet: Bool
    @Binding var weight: Int
    @Binding var height: Int


        var body: some View {
                GeometryReader { gr in
                    VStack {
                        VStack {
                            Text("Gewicht in kg")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 10)

                            Picker("Gewicht", selection: $weight) {
                                ForEach(50..<200) {
                                    Text("\($0) kg").tag($0)
                                }
                            }.pickerStyle(WheelPickerStyle())

                        }.background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.white).shadow(radius: 1))
                        VStack {
                            Button(action: {
                                self.enableWeightSheet.toggle()
                            }) {
                                Text("Klaar").fontWeight(Font.Weight.bold)
                            }.padding()
                                .buttonStyle(SecondaryButtonStyle())

                        }
                    }.position(x: gr.size.width / 2 ,y: gr.size.height - 200)
                }
        }
    }
