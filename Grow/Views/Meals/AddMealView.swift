//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI

struct AddMealView : View {
    @Binding var text: String

    @State private var isEditing = false
    
    var body: some View {
//            Form {
                HStack {

                    TextField("Search ...", text: $text)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            self.isEditing = true
                        }

                    if isEditing {
                        Button(action: {
                            self.isEditing = false
                            self.text = ""

                        }) {
                            Text("Cancel")
                        }
                        .padding(.trailing, 10)
                        .transition(.move(edge: .trailing))
                        .animation(.default)
                    }
                }.navigationBarItems( trailing: Text("Nieuw").foregroundColor(Color.init("textColor")))
////            .navigationBarTitle(Text(""))
//            .navigationBarItems( trailing: Text("Nieuw").foregroundColor(Color.init("textColor")))
//        }
        //
//        Button("Ga terug", action: {
//
//            self.showAddMealView.toggle()
//
//        })

    }
}

//struct AddMealView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddMealView()
//    }
//}
