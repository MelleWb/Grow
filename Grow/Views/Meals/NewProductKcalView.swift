//
//  NewProductKcalView.swift
//  Grow
//
//  Created by Melle Wittebrood on 21/08/2021.
//

import SwiftUI

struct NewProductKcalView: View {
    @State var productKcal: String = ""
    @State var productKoolh: String = ""
    @State var productEiwit: String = ""
    @State var productVet: String = ""
    @State var productVezel: String = ""
    
    var body: some View {
        Form{
           HStack{
            Text("Calorieën")
            TextField("0", text: $productKcal)
                .multilineTextAlignment(.trailing)
            }
            HStack{
                Text("Koolhydraten (g)")
                TextField("0", text: $productKoolh)
                .multilineTextAlignment(.trailing)
            }
            HStack{
                Text("Eiwitten (g)")
                TextField("0", text: $productEiwit)
                .multilineTextAlignment(.trailing)
            }
            HStack{
                Text("Vetten (g)")
                TextField("0", text: $productVet)
                .multilineTextAlignment(.trailing)
            }
            HStack{
                Text("Vezels (g)")
                TextField("0", text: $productVezel)
                .multilineTextAlignment(.trailing)
            }
        }.listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Nieuw product"))
        .navigationBarItems(trailing:
                                Button(action: {print("hallo")}) { Text("Opslaan") }
                                   .disabled(self.productKcal.isEmpty)
    )}
}

struct NewProductKcalView_Previews: PreviewProvider {
    static var previews: some View {
        NewProductKcalView()
    }
}
