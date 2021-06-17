//
//  TrainingFunctions.swift
//  Grow
//
//  Created by Swen Rolink on 17/06/2021.
//

import Foundation

struct JsonParser {
    var trainingJSONString:String
    var trainingOverview: overview
    
    init(){
        trainingJSONString = JsonOverviewResponse().jsonString
    
    let jsonData = trainingJSONString.data(using: .utf8)!
        trainingOverview = try! JSONDecoder().decode(overview.self, from: jsonData)
    }
}

func determineImage(type: String) -> String {
    var image: String
    
    if type == "Bovenlichaam"{
        image = "upper"
    }else if type == "Onderlichaam"{
        image  = "lower"
    } else {
        image = "rest"
    }
    
    return image
}

func getRepKGByPb(pb:Int, reps:Int) -> Double{
    
    var percentage: Double = 0

    switch reps {
    case 1:
        percentage = 1
    case 2:
        percentage = 0.97
    case 3:
        percentage = 0.94
    case 4:
        percentage = 0.92
    case 5:
        percentage = 0.89
    case 6:
        percentage = 0.86
    case 7:
        percentage = 0.83
    case 8:
        percentage = 0.81
    case 9:
        percentage = 0.78
    case 10:
        percentage = 0.75
    case 11:
        percentage = 0.73
    case 12:
        percentage = 0.71
    case 13:
        percentage = 0.70
    case 14:
        percentage = 0.68
    case 15:
        percentage = 0.67
    default:
        percentage = 0.60
    }
    let roundedKGs = Double(pb) * percentage
    return roundedKGs.rounded()
}
