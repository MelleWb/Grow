//
//  TrainingView.swift
//  Grow
//
//  Created by Melle Wittebrood on 29/07/2021.
//

/*
import SwiftUI
//import KeyboardToolbar


struct TrainingDetailView: View {
    var name: String
    var image: String
    var exercises: [exercises]?
    
    @State private var showtextFieldToolbar = false
    @State var repsCount: String
    
    func determineSetName(exercizeCount: Int) -> String {
        if(exercizeCount==1){
            return "Set"
        }
        else {
            return "Superset"
        }
    }
    
    let toolbarItems: [KeyboardToolbarItem] = [
//        .init(systemName: "bold", callback: {}),
//        .init(systemName: "italic", callback: {}),
//        .init(systemName: "underline", callback: {}),
        .dismissKeyboard
    ]
    
        var body: some View {
                VStack {
                    Image(image)
                        .resizable()
                        .frame(width: 45, height: 50)
                    Text(name)
                        .font(.title)
                    
                }.padding().navigationBarTitle(Text(name), displayMode: .inline)
            List{
                    ForEach(exercises ?? [], id: \.self){ exercise in
                        Section(header:Text(determineSetName(exercizeCount: exercise.set.count))){
                            ForEach(exercise.set, id: \.self){ set in
                                ExercizeRow(name: set.exercise.name, description: set.exercise.description, reps: set.exercise.reps, sets:set.exercise.sets, kg:set.exercise.kg)
                            }
                        }
                    }
            }//.keyboardToolbar(toolbarItems)
        }
}

    struct TableRow: View {

    @Binding var reps: Int
    @Binding var sets: Int
    @Binding var kg: Int

    @State var estmtdKGS: String = ""
    @State var repsCountSet: String = ""

    var body: some View{
        let estmtdKG: String = String(getRepKGByPb(pb: kg, reps: reps))
                    HStack{
                        VStack(alignment: .leading ){
                            Text("Reps")
                            TextField("0", text: $repsCountSet).keyboardType(.numberPad).padding(.leading, 12)
                        }
                        VStack(alignment: .leading){
                            Text("Kgs")
                            TextField(estmtdKG, text: $estmtdKGS).keyboardType(.numberPad)
                        }
                    }
            }
    }

    struct ExercizeRow: View {
        @State var repsCount: String = ""
        @State var setsCount: String = ""
        @State var estmtdKGS: String = ""
        @State var repsCountSet: String = ""
        @State private var numbers = [Int]()
        @State private var currentNumber = 0

        @State var name: String
        var description: String
        @State var reps: Int
        @State var sets: Int
        @State var kg: Int
        @State var exercises: [exercises]?

        var body: some View {

            let setsString: String = String(sets)
            let repsString: String = String(reps)
            let estmtdKG: String = String(getRepKGByPb(pb: kg, reps: reps))
            
        ZStack{
            Button("") {}
            NavigationLink(destination: ExerciseDetailView(name: name, description: description)){
                Text(name).font(.headline).padding(.bottom, 5).foregroundColor(Color.init("textColor"))
            }
        }
            VStack{
                    HStack{
                        VStack(alignment: .leading){
                            Text("sets")
                            TextField(setsString, text: $setsCount).keyboardType(.numberPad).padding(.leading, 10)
                        }
                        VStack(alignment: .leading){
                            Text("Reps")
                            TextField(repsString, text: $repsCount).keyboardType(.numberPad).padding(.leading, 12)
                        }
                        VStack(alignment: .leading){
                            Text("Kgs")
                            TextField(estmtdKG, text: $estmtdKGS).keyboardType(.numberPad)
                            }
                    }
            }
                ForEach(numbers, id: \.self) { number in
                    TableRow(reps: $reps, sets: $sets, kg: $kg)
                        }.onDelete(perform: removeRows)
                                    
            Button("Voeg toe") {
                self.numbers.append(self.currentNumber)
                self.currentNumber += 1
            }
        }
        func removeRows(at offsets: IndexSet) {
            numbers.remove(atOffsets: offsets)
        }
    }
*/
