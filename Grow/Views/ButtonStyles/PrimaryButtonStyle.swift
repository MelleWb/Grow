//
//  PrimaryButtonStyle.swift
//  Grow
//
//  Created by Swen Rolink on 05/12/2021.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let height: CGFloat = 50
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
           .font(.headline)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.9) : Color.accentColor)
            .cornerRadius(15.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

