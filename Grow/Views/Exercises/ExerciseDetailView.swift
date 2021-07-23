//
//  ExerciseDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 30/06/2021.
//

import SwiftUI

struct ExerciseDetailView: View {
    
    @State var exercise: Exercise
    
    var body: some View {
        NavigationView{
            VStack{
                Text(exercise.description ?? "")
            }
        }.navigationTitle(exercise.name)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
