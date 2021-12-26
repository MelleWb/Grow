//
//  ChevronButtonStyle.swift
//  Grow
//
//  Created by Swen Rolink on 29/11/2021.
//

import SwiftUI


struct ChevronButtonStyle: ButtonStyle {
    let height: CGFloat = 25
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .foregroundColor(configuration.isPressed ? Color.gray : Color.accentColor)
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
    }
}
