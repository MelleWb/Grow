//
//  HealthKit.swift
//  Grow
//
//  Created by Swen Rolink on 25/09/2021.
//

import Foundation
import HealthKit

class HealthKitSetupAssistant {
    
    private enum HealthkitSetupError: Error {
      case notAvailableOnDevice
      case dataTypeNotAvailable
    }
    
    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        
        
        //1. Check to see if HealthKit Is Available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
          completion(false, HealthkitSetupError.notAvailableOnDevice)
          return
        }
        
        //2. Prepare the data types that will interact with HealthKit
        guard   let bodyFatPercentage = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
                let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
                let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)
        else {
                
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }

        let activitySummaryType = HKObjectType.activitySummaryType()
        
        //3
        let healthKitTypesToRead: Set<HKObjectType> = [bodyFatPercentage,
                                                       bodyMass,
                                                       stepCount,
                                                       activitySummaryType]
        
        //4. Request Authorization
        HKHealthStore().requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
          completion(success, error)
        }
    }
}

class HealthKitDataStore {
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
      
    //1. Use HKQuery to load the most recent samples.
    let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                          end: Date(),
                                                          options: .strictEndDate)
        
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                          ascending: false)
        
    let limit = 1
        
    let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                    predicate: mostRecentPredicate,
                                    limit: limit,
                                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        
        //2. Always dispatch to the main thread when complete.
        DispatchQueue.main.async {
            
          guard let samples = samples,
                let mostRecentSample = samples.first as? HKQuantitySample else {
                    
                completion(nil, error)
                return
          }
            
          completion(mostRecentSample, nil)
        }
      }
     
    HKHealthStore().execute(sampleQuery)
    }
    
    class func getTodayStepCount(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let sum = result?.sumQuantity() else {
                    completion(nil, error)
                    return
                }
                
                completion(sum.doubleValue(for: HKUnit.count()), nil)
            }
        }
        
        HKHealthStore().execute(query)
    }

    class func getTodayActiveEnergySummary(completion: @escaping (Double?, Double?, Error?) -> Void) {
        let calendar = Calendar.current
        var todayComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: Date())
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var tomorrowComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: tomorrowDate)
        todayComponents.calendar = calendar
        tomorrowComponents.calendar = calendar

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: todayComponents, end: tomorrowComponents)

        let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
            DispatchQueue.main.async {
                guard let summary = summaries?.first else {
                    completion(nil, nil, error)
                    return
                }

                let unit = HKUnit.kilocalorie()
                let burned = summary.activeEnergyBurned.doubleValue(for: unit)
                let goal = summary.activeEnergyBurnedGoal.doubleValue(for: unit)
                completion(burned, goal, nil)
            }
        }

        HKHealthStore().execute(query)
    }
}
