//
//  TrainingFunctions.swift
//  Grow
//
//  Created by Swen Rolink on 17/06/2021.
//

import Foundation

/*
struct JsonParser {
    var trainingJSONString:String
    var trainingOverview: Overview
    
    init(){
        trainingJSONString = JsonOverviewResponse().jsonString
    
    let jsonData = trainingJSONString.data(using: .utf8)!
        trainingOverview = try! JSONDecoder().decode(Overview.self, from: jsonData)
    }
}
*/
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

