//
//  ManageProductDetailView.swift
//  Grow
//
//  Created by Swen Rolink on 28/03/2022.
//

import SwiftUI

struct ManageProductDetailView: View {
    @EnvironmentObject var foodModel: FoodDataModel
    @Environment(\.dismiss) private var dismiss

    @State var documentID: String
    @State private var product: Product = Product()
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Product laden")
            } else {
                ProductEditorView(product: product, saveButtonTitle: "Opslaan") { product in
                    foodModel.createProduct(product: product)
                } onSuccess: {
                    dismiss()
                }
            }
        }
        .onAppear {
            foodModel.getProductDetails(documentID: documentID) { product, _ in
                if let product {
                    self.product = product
                    self.product.documentID = documentID
                    isLoading = false
                } else {
                    dismiss()
                }
            }
        }
    }
}
