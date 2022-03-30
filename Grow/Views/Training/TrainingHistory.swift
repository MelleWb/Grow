//
//  TrainingHistory.swift
//  Grow
//
//  Created by Swen Rolink on 03/09/2021.
//

import SwiftUI

struct TrainingHistoryOverview: View {
    
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @EnvironmentObject var userModel: UserDataModel
    
    var body: some View {
        VStack{
            List{
                Section{
                    ForEach(self.statisticsModel.trainingHistory, id: \.self) { training in
                        ZStack{
                            Button(""){}
                            NavigationLink(destination: TrainingHistoryDetail(training: training)){
                                TrainingHistoryRow(training: training)
                            }
                        }
                    }.onDelete(perform: deleteTrainingHistory)
                }
            }
        }.listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Training historie"))
        .onAppear {
            self.statisticsModel.loadTrainingHistory()
        }
    }
    func deleteTrainingHistory(at offsets: IndexSet) {
        let index: Int = offsets[offsets.startIndex]
        self.statisticsModel.removeTrainingHistory(for: index)
        self.userModel.getTrainingStatsForCurrentWeek()
    }
}

struct TrainingHistoryRow: View {
    @State var training: TrainingStatistics
    var body: some View{
        HStack{
            Text(training.trainingDate, style: .date)
            Text(String(training.trainingVolume))
        }
    }
}


struct TrainingHistoryDetail: View {
    
    @EnvironmentObject var statisticsModel: StatisticsDataModel
    @State var training: TrainingStatistics
    
    var body: some View {
        VStack{
            List{
                ForEach(self.training.exerciceStatistics ?? [], id: \.self){ stats in
                    VStack(alignment: .leading){
                        Text(stats.exerciseName)
                            HStack{
                                Text("Set: \(stats.set + 1)")
                                Text("Reps: \(stats.reps ?? 0)")
                                Text("Gewicht: \(NumberHelper.roundNumbersMaxTwoDecimals(unit: stats.weight ?? 0))")
                            }
                    }.padding()
                    }
                }
            }.listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Training overzicht"))
        }
    }
