//
//  NewProductsNutritionView.swift
//  Grow
//
//  Created by Melle Wittebrood on 21/08/2021.
//

import SwiftUI

struct NewProductsNutritionView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Binding var showProductsNutritionView: Bool
    @Binding var showAddProduct: Bool
    @State var product: Product

    var body: some View {
        ProductEditorView(product: product, saveButtonTitle: "Opslaan") { product in
            foodModel.createProduct(product: product)
        } onSuccess: {
            showAddProduct = false
            showProductsNutritionView = false
        }
    }
}
