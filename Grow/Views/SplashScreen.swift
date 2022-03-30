//
//  SplashScreen.swift
//  Grow
//
//  Created by Swen Rolink on 25/03/2022.
//

import SwiftUI

struct SplashScreen: View {
    @State var screenText: String = ""
    var body: some View {
        VStack{
            withAnimation (
                .linear(duration: 5)) {
            LottieView(animation: "muscleanimation", loopMode:.repeat(1)).frame(width: 250, height: 300)
                }
            
            Text(screenText)
                .font(.title)
                
        }.onAppear(perform: {
            withAnimation (
                .easeInOut(duration: 1)) {
                    self.screenText = "Grow"
                }
        })
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
