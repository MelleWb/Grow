//
//  WorkoutOfTheDayView.swift
//  Grow
//
//  Created by Swen Rolink on 31/07/2021.
//

import SwiftUI

struct WorkoutOfTheDayView: View {
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        Form{
            Text("Laat training zien")
        }.navigationTitle("Training van vandaag")
    }
}

struct WorkoutOfTheDayView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutOfTheDayView()
    }
}
