//
//  PreviewBars.swift
//  Grow
//
//  Created by Swen Rolink on 11/02/2022.
//

import SwiftUI

struct PreviewBars: View {
    var body: some View {
//        List{
//            Section {
                ZStack {
                    VStack(alignment: .leading, spacing: 10){
                        ProgressBarLinear(value: Binding.constant(0.91))
                        ProgressBarLinear(value: Binding.constant(1.0))
                        ProgressBarLinear(value: Binding.constant(1.1))
                        ProgressBarLinear(value: Binding.constant(0.95))
                        ProgressBarLinear(value: Binding.constant(0.90))
                    }
                    VerticalLeftFoodBar()
                    VerticalFoodBar()
                    VerticalRightFoodBar()
                }
//            }
//        }
    }
}
