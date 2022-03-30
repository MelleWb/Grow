//
//  FormRowButtonStyle.swift
//  Grow
//
//  Created by Swen Rolink on 06/12/2021.
//

import SwiftUI

struct FormRowButtonStyle: ButtonStyle {
    let height: CGFloat = 25
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.init("blackWhite"))
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
    }
}
