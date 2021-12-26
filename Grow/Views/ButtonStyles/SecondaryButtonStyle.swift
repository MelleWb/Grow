//
//  SecondaryButtonStyle.swift
//  Grow
//
//  Created by Swen Rolink on 05/12/2021.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    let height: CGFloat = 60
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
           .font(.headline)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .foregroundColor(.accentColor)
            .background(Color.white)
            .cornerRadius(15.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
