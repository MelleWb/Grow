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
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
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
                                catch {
                                    print("Oops")
                                }
                            }
                        )
                        
                        Picker("Gewicht", selection: weightBinding) {
                            ForEach(50..<200) {
                                Text("\($0) kg").tag($0)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.init("textField"))
                            .shadow(radius: 1)
                    )
                    
                    Button(action: {
                        self.enableWeightSheet.toggle()
                    }) {
                        Text("Klaar").fontWeight(Font.Weight.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
    }
}
