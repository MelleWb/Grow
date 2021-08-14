//
//  Helpers.swift
//  Grow
//
//  Created by Swen Rolink on 24/06/2021.
//

import SwiftUI
import Firebase
import Combine

class DateHelper {

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
        
        let cal = Calendar.current
        //weekday
        let weekday = cal.component(.weekday, from: Date())

        var dateComp = cal.dateComponents([.hour, .minute, .second, .day, .month, .year], from: Date())
        //Start Date of the week - Monday
        dateComp.day = dateComp.day! - (weekday - 2)// start date of week
        
        DateArray = [(cal.date(from: dateComp)!)]

        //End Date of the Week - Zondag
        dateComp = cal.dateComponents([.hour, .minute, .second, .day, .month, .year], from: Date())

        dateComp.day = dateComp.day! + (7 - (weekday - 1))

        DateArray.append(cal.date(from: dateComp)!)
        
        print(DateArray)
        
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
