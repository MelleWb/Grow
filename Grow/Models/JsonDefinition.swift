//
//  TrainingDetails.swift
//  Grow
//
//  Created by Swen Rolink on 12/06/2021.
//

import Foundation

struct overview: Codable  {
    var trainee: String
    var days: [days]
}

struct days: Codable, Hashable{
    var type: String
    var exercises: [exercises]?
    
    static func ==(lhs: days, rhs: days) -> Bool {
        return lhs.exercises == rhs.exercises
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(exercises)
    }
}

struct exercises: Codable, Hashable {
    var set: [set]
    
    static func ==(lhs: exercises, rhs: exercises) -> Bool {
        return lhs.set == rhs.set
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(set)
    }
}

struct set: Codable, Hashable {
    var exercise: exercise
    
    static func ==(lhs: set, rhs: set) -> Bool {
        return lhs.exercise == rhs.exercise
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(exercise)
    }
}

struct exercise: Codable, Hashable {
    var name: String
    var reps: Int
    var sets: Int
    var pb: Int?
    
    static func ==(lhs: exercise, rhs: exercise) -> Bool {
        return lhs.name == rhs.name
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
