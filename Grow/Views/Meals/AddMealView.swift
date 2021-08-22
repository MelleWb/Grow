//
//  AddMealView.swift
//  Grow
//
//  Created by Melle Wittebrood on 04/08/2021.
//

import SwiftUI

struct AddMealView : View {
    @Binding var text: String
    @EnvironmentObject var foodModel : FoodDataModel
//    @State var AddproductView = false
    @State var showAddProduct: Bool = false

    @State private var isEditing = false
    
    var body: some View {
        
        if showAddProduct {
            NavigationLink(
                destination: AddProductView().environmentObject(foodModel),
                        isActive: $showAddProduct
                    ) {}.isDetailLink(true).hidden().frame(width: 0, height: 0, alignment: .top)
        }
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
                }.navigationBarItems(trailing:
                                        ZStack{
                                        Button(action: {
                                            self.showAddProduct = true
                                        }) {
                                            Text("Nieuw").foregroundColor(Color.init("textColor"))
                                                   }
                                    }
        )}
}
