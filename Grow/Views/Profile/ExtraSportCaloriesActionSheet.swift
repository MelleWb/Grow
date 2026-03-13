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
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
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
                                catch {
                                    print("Oops")
                                }
                            }
                        )
                        
                        Picker("Extra percentage calorieën", selection: calorieBinding) {
                            ForEach(0..<100) {
                                Text("+ \($0)%").tag($0)
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
                        self.enableExtraCalorieSheet.toggle()
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
