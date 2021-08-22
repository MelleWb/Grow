//
//  TrainingVolumeView.swift
//  Grow
//
//  Created by Swen Rolink on 22/08/2021.
//

import SwiftUI

struct TrainingVolumeView: View {
    
    @EnvironmentObject var statisticsModel : StatisticsDataModel
    
    var body: some View {
        List{
        if self.statisticsModel.schemaStatistics.routineStats != nil {
            ForEach(self.statisticsModel.schemaStatistics.routineStats!, id:\.self){routineStats in
                VStack(alignment:.leading){
                    Text(routineStats.type).font(.headline).foregroundColor(.accentColor)
                        HStack{
                            ForEach(routineStats.trainingStats, id:\.self){ trainingStats in
                                ProgressBarVertical(value: trainingStats.volumePercentage ?? 0, label: String(trainingStats.trainingVolume))
                            }
                        }
                    }
                }
            }
        }.onAppear(perform:{
            self.statisticsModel.getStatisticsForCurrentSchema()
        })
        .navigationTitle(Text("Volume per training"))
    }
}

struct TrainingVolumeView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingVolumeView()
    }
}
