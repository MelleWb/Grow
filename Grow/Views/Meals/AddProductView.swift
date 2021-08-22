//
//  AddProductView.swift
//  Grow
//
//  Created by Melle Wittebrood on 19/08/2021.
//

import SwiftUI
import Firebase

struct AddProductView: View {
    @EnvironmentObject var foodModel : FoodDataModel
    @State var nameProduct: String = ""
    @State var amountOf: String = ""
    @State private var selectedUnit = "Grammen"
    let unit = ["Grammen", "Milimeters"]
    @State var showProductKcal: Bool = false
    
    var body: some View {
        
        if showProductKcal {
            NavigationLink(
                destination: NewProductKcalView().environmentObject(foodModel),
                        isActive: $showProductKcal
                    ) {}.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
        }
        
        Form{
           HStack{
            Text("Naam")
            TextField("Voer de naam in", text: $nameProduct)
                .multilineTextAlignment(.trailing)
            }
            HStack{
                ZStack{
                Button("", action:{})
                Picker("Eenheid", selection: $selectedUnit) {
                                ForEach(unit, id: \.self) {
                                    Text($0)
                                }
                            }
                }
            }
            HStack{
                Text("Portiegrootte (g)")
                TextField("100 g", text: $amountOf)
                .multilineTextAlignment(.trailing)
            }
        }.listStyle(InsetGroupedListStyle())
        .navigationTitle(Text("Nieuw product"))
        .navigationBarItems(trailing:
                                Button(action: {self.showProductKcal = true}) { Text("Volgende") }
                                   .disabled(self.nameProduct.isEmpty)
    )}
}

struct AddProductView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductView()
    }
}
