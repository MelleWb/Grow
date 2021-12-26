//
//  LinkButtonStyle.swift
//  Grow
//
//  Created by Swen Rolink on 10/12/2021.
//

import SwiftUI

struct LinkButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
           .font(.footnote)
           .foregroundColor(configuration.isPressed ? .gray : .black)
           .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

