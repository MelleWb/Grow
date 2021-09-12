//
//  ProgressIndicator.swift
//  Grow
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI
import Introspect

struct ProgressIndicator<Content>: View where Content: View {

    @Binding var isShowing: Bool
    var loadingText: String
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)

                VStack {
                    ProgressView(loadingText)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)

            }
        }
        .introspectTabBarController { (UITabBarController) in
            UITabBarController.tabBar.isHidden = isShowing
        }
    }

}
