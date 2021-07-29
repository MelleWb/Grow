//
//  TrainingDaySelectionView.swift
//  Grow
//
//  Created by Swen Rolink on 29/07/2021.
//

import SwiftUI

struct TrainingDaySelectionView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                StaticWeekDaysView()
                    .frame(width: geometry.size.width/2, height: geometry.size.height)
                    .disabled(true)
                DynamicTrainingDaysView()
                    .frame(width: geometry.size.width/1.5)
                    .offset(x: geometry.size.width/3.5)
            }
        }
    }
}
struct StaticWeekDaysView: View{
    
    var weekDays:[String] = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"]
    
    var body: some View {
        List{
            ForEach(0..<weekDays.count){ i in
            Text(weekDays[i])
            }
        }
    }
}

struct dummyTrainingDays: Identifiable, Hashable{
    var id = UUID()
    var type: String
}

struct DynamicTrainingDaysView: View {
    @State var trainingDays:[dummyTrainingDays] = [dummyTrainingDays(type: "Rust"), dummyTrainingDays(type: "Training"),dummyTrainingDays(type: "Training"),dummyTrainingDays(type: "Training"),dummyTrainingDays(type: "Rust"),dummyTrainingDays(type: "Training"),dummyTrainingDays(type: "Training")]
    
    @State var isEditMode: EditMode = .active
    
    var body: some View {
        List{
            ForEach(trainingDays, id:\.self){ day in
                HStack{
                    if day.type == "Rust"{
                        Image(systemName: "powersleep").foregroundColor(Color.init("textColor"))
                    }
                    else {
                        Image(systemName: "bolt").foregroundColor(Color.init("textColor"))
                    }
                    Text(day.type)
                }
            }.onMove(perform: moveRow)
        }.environment(\.editMode, self.$isEditMode)
    }
    
    private func moveRow(source: IndexSet, destination: Int){
        self.trainingDays.move(fromOffsets: source, toOffset: destination)
        }
}

struct TrainingDaySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDaySelectionView()
    }
}
