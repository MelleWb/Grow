//
//  LoadingView.swift
//  TestApp
//
//  Created by Swen Rolink on 20/02/2022.
//

import SwiftUI

struct LoadingView: View {
    
    @State var loadingText:String
    
    var body: some View {
        VStack{
            LottieView(animation: "muscleanimation").frame(width: 150, height: 150)
            Text(loadingText)
                .padding(.bottom)
                .font(.subheadline)
        }
        .background(Color.secondary.colorInvert())
        .foregroundColor(Color.primary)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(loadingText: "Dashboard laden")
    }
}
