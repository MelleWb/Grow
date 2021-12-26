//
//  Helpers.swift
//  Grow
//
//  Created by Swen Rolink on 24/06/2021.
//

import SwiftUI
import Firebase
import Combine

class NumberHelper{
    class func roundedNumbersFromDouble(unit: Double) -> String {
        
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .none

        return formatter.string(from: NSNumber(value: unit)) ?? "0"
    }
    
    class func roundNumbersMaxTwoDecimals(unit: Double) -> String {
        var formattedValue = String(format: "%.2f", unit)
        
        for _ in 1...3 {
            
            //Check if formattedValue ends with a 0. Remove the last character
            let endOfNumber = formattedValue.suffix(1)
            
            if endOfNumber == "0" || endOfNumber == "."{
                //if it ends with a zero. Just remove it from the string
                let start = formattedValue.index(formattedValue.startIndex, offsetBy: 0)
                let end = formattedValue.index(formattedValue.endIndex, offsetBy: -1)
                let range = start..<end
                let formattedSubString = formattedValue[range]
                formattedValue = String(formattedSubString)
            }
        }
        return formattedValue
    }
}

class DateHelper {
    
    private enum DateError: Error {
        case invalidYear
    }
    
    class func getAgeNumber(dateOfBirth: Date) throws -> Int{
        
        let today = Date()
        let yearCompOfToday = Calendar.current.dateComponents([.year], from: today)
        let yearCompOfUser = Calendar.current.dateComponents([.year], from: dateOfBirth)
        
        guard let yearOfToday = yearCompOfToday.year else {
            throw DateError.invalidYear
        }
        
        guard let yearOfUser = yearCompOfUser.year else {
            throw DateError.invalidYear
        }
        
        return yearOfToday - yearOfUser
    }

    class func from(year: Int, month: Int, day: Int) -> Date {
        let gregorianCalendar = NSCalendar(calendarIdentifier: .gregorian)!

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        let date = gregorianCalendar.date(from: dateComponents)!
        return date
    }

    class func parse(_ string: String, format: String = "yyyy-MM-dd") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.default
        dateFormatter.dateFormat = format

        let date = dateFormatter.date(from: string)!
        return date
    }
    
    class func calcWeekDates() -> [Date]{
        
        var DateArray: [Date]

        var customCalendar = Calendar(identifier: .gregorian)
        customCalendar.firstWeekday = 2
        
        var startDate = Date()
        var interval = TimeInterval()
        let _ = customCalendar.dateInterval(of: .weekOfMonth, start: &startDate, interval: &interval, for: Date())
        let endDate = startDate.addingTimeInterval(interval - 2)
        print(startDate, endDate)
        
        DateArray = [startDate]
        DateArray.append(endDate)
        
        return DateArray
    }
}

class NumbersOnly: ObservableObject {
    @Published var value = "" {
        didSet {
            let filtered = value.filter { $0.isNumber }
            
            if value != filtered {
                value = filtered
            }
        }
    }
}

//DB Functions

class Authentication {
    
    static func signIn(username: String, password: String, completion: @escaping(Bool, String) -> Void){
        Auth.auth().signIn(withEmail: username, password: password) {
            authResult, error in
            
            if (error?.localizedDescription != nil){
                completion(false, error!.localizedDescription)
            }else if(authResult?.user != nil){
                completion(true, "")
            } else {
                print("Geen authenticatie")
            }
        }
    }
}

class FirebaseAuthentication: ObservableObject {
    
    @Published var authObject: AuthDataResult?
    @Published var errorText: String = ""
    @Published var isAuthenticated: Bool = false
    
    func signIn(username: String, password: String){
        Auth.auth().signIn(withEmail: username, password: password) {
            authResult, error in
            
            if (error?.localizedDescription != nil){
                print(error!.localizedDescription)
                DispatchQueue.main.async {
                    self.errorText = error!.localizedDescription
                }
            }else if(authResult?.user != nil){
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.authObject = authResult
                }
            } else {
                print("Geen authenticatie")
            }
        }
    }
}

struct AddButton<Destination : View>: View {

    var destination:  Destination

    var body: some View {
        NavigationLink(destination: self.destination) { Image(systemName: "plus") }
    }
}
