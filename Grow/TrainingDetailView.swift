//
//  TrainingDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 11/06/2021.
//

import SwiftUI

struct TrainingDetailView: View {
    var name: String
    var image: String
    var exercises: [exercises]?
    
        var body: some View {
            
            VStack {
                Image(image)
                    .resizable()
                    .frame(width: 75, height: 75)
                    .shadow(radius: 10)
                Text(name)
                    .font(.title)
                
            }.padding().navigationBarTitle(Text(name), displayMode: .inline)
            List{
                ForEach(exercises ?? [], id: \.self){ exercises in
                    Section(header:Text("Superset")){
                    ForEach(exercises.set, id: \.self){ set in
                        ExercizeRow(name: set.exercise.name, reps:set.exercise.reps, sets:set.exercise.sets, pb:set.exercise.pb ?? 0 )
                            }
                        }
                    }
                }
            }
        }

    struct ExercizeRow: View {
    
        var name: String
        var reps: Int
        var sets: Int
        var pb: Int

        var body: some View {
            
            let setsString: String = String(sets)
            let repsString: String = String(reps)
            let estmtdKG: String = String(getRepKGByPb(pb: pb, reps: reps))
            
                HStack{
                    VStack (alignment: .leading) {
                        Text(name).font(.headline).padding(.bottom, 5)
                        Text(setsString + " sets").font(.subheadline).padding(.bottom, 5)
                        Text(repsString + " reps").font(.subheadline).padding(.bottom, 5)
                        Text("Estimated " + estmtdKG + " kgs").font(.subheadline)
                    }
                    
                }.padding(.init(top: 12, leading: 5, bottom: 12, trailing: 5))
                
            }
    }
    
struct TrainingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDetailView(name: "Upper body", image: "upper", exercises:[])
        }
    }
