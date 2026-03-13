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
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
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
                                catch {
                                    print("Oops")
                                }
                            }
                        )
                        
                        Picker("Lengte in cm", selection: heightBinding) {
                            ForEach(100..<250) {
                                Text("\($0) cm").tag($0)
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
                        self.enableHeightSheet.toggle()
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
