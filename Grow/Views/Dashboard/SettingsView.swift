//
//  SettingsView.swift
//  Grow
//
//  Created by Swen Rolink on 02/09/2021.
//

import SwiftUI
import Firebase

struct SettingsView: View {
    
    @EnvironmentObject var foodModel: FoodDataModel
    @EnvironmentObject var userModel: UserDataModel
    @State var showProfileView: Bool = false
    
    //IAP
    @ObservedObject var storeManager = StoreManager()
    
    var body: some View {
        NavigationView{
            VStack{
                List{
                    Section{
                        HStack{
                            ZStack{
                                Button(""){}
                                NavigationLink(destination: SlimProductOverview()){
                                    Image(systemName: "doc.text")
                                        .resizable()
                                        .foregroundColor(.accentColor)
                                        .frame(width: 15, height: 20, alignment: .center)
                                        Text("Producten")
                                    }
                            }
                        }
                        HStack{
                            ZStack{
                                Button(""){}
                                NavigationLink(destination: Profile()){
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .foregroundColor(.accentColor)
                                        .frame(width: 20, height: 20, alignment: .center)
                                        Text("Profiel")
                                    }
                            }
                        }
                        
                    }
                    ForEach(self.storeManager.myProducts, id: \.self) { product in
                    HStack {
                           VStack(alignment: .leading) {
                               Text(product.localizedTitle)
                                   .font(.headline)
                               Text(product.localizedDescription)
                                   .font(.caption2)
                           }
                           Spacer()
//                           if UserDefaults.standard.bool(forKey: product.productIdentifier) {
//                               Text ("Gekocht")
//                                   .foregroundColor(.green)
//                           } else {
                               Button(action: {
                                   let _ = self.storeManager.purchaseProduct(product: product)
                               }) {
                                   Text("??? \(product.price)")
                               }
                                   .foregroundColor(.blue)
//                           }
                       }
                }
            }

        }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.storeManager.restoreProducts()
                    }) {
                        Text("Herstel aankopen")
                    }
                }
            })
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(Text("Instellingen"))
    }
        
        .navigationViewStyle(.stack)
        .onAppear(perform: {
            storeManager.startObserving()
            storeManager.getProducts()
        })
        .onDisappear {
            storeManager.stopObserving()
        }
    }
}

//    struct ManageProductOverview : View {
//
//        @State var searchText = ""
//        @State var searching = false
//        @State var showAddProduct: Bool = false
//        @State var showManageProductDetailView: Bool = false
//        @EnvironmentObject var foodModel : FoodDataModel
//
//        func delete(at offsets: IndexSet) {
//
//            let index = offsets[offsets.startIndex]
//            let documentID:String = foodModel.products[index].documentID ?? ""
//
//            self.foodModel.deleteProduct(documentID: documentID)
//
//        }
//
//        var body: some View {
//            VStack{
//            List {
//                    SearchBar(searchText: $searchText, searching: $searching)
//                    ForEach(foodModel.products.filter({ (product: Product) -> Bool in
//                        return product.name.range(of: searchText, options: .caseInsensitive) != nil || searchText == ""
//                    }), id: \.self) { product in
//                        ManageProductRow(product: SlimProduct(documentID: product.documentID!, name: product.name))
//                    }.onDelete(perform: delete)
//            }
//            }
//            .listStyle(InsetGroupedListStyle())
//                    .sheet(isPresented: $showAddProduct, content: {AddProductView(showAddProduct: $showAddProduct)})
//                .toolbar(content: {Button(action: {
//                    self.showAddProduct = true
//                }) {
//                    Text("Nieuw").foregroundColor(Color.init("textColor"))
//                }})
//        }
//    }
//}

//struct ManageProductRow: View{
//    @State var product: Product
//    @State var showManageProductDetailView: Bool = false
//    
//    var body: some View{
//        ZStack{
//            Button(""){}
//            NavigationLink(destination:ManageProductDetailView(documentID: product.documentID!, showManageProductDetailView: $showManageProductDetailView),isActive:$showManageProductDetailView){
//                        Text(product.name)
//            }
//        }
//    }
//}

//struct ManageProductDetailView: View {
//    @EnvironmentObject var foodModel : FoodDataModel
//    @State var product: Product
//    let unit = ["Grammen", "Milliliters"]
//    @Binding var showManageProductDetailView: Bool
//
//    @State var portionName: String = ""
//    @State var portionAmount: String = ""
//    @State var kcalInput: String = ""
//    @State var carbsInput: String = ""
//    @State var proteinInput: String = ""
//    @State var fatInput: String = ""
//    @State var fiberInput: String = ""
//    
//    func calculateKcal(){
//        self.product.kcal = 0
//        
//        let calcCarbs = self.product.carbs * 4
//        let calcProtein = self.product.protein * 4
//        let calcFat = self.product.fat * 9
//        let calcFiber = self.product.fiber * 2
//        
//        self.product.kcal = calcCarbs + calcProtein + calcFat + calcFiber
//        self.kcalInput = NumberHelper.roundedNumbersFromDouble(unit: self.product.kcal)
//    }
//    
//    var body: some View {
//            Form{
//                Section{
//                   HStack{
//                    Text("Naam")
//                    TextField("Voer de naam in", text: $product.name)
//                        .multilineTextAlignment(.trailing)
//                    }
//                    HStack{
//                        ZStack{
//                        Button("", action:{})
//                            Picker("Eenheid", selection: $product.unit) {
//                                        ForEach(unit, id: \.self) {
//                                            Text($0)
//                                        }
//                                    }
//                        }
//                    }
//                }
//                if self.product.portions.count > 1 {
//                    Section(header:Text("Portiegroottes")){
//                        List{
//                            ForEach(self.product.portions, id:\.self){ portion in
//                                    HStack{
//                                        Text(portion.name)
//                                        Spacer()
//                                        Text("\(portion.amount) gram")
//                                }
//                            }.onDelete(perform: deletePortion)
//                        }
//                    }
//                }
//                
//                Section(header:Text("Voeg portiegrootte toe")){
//                    
//                    HStack{
//                        TextField("Portienaam", text:$portionName)
//                            .multilineTextAlignment(.leading)
//                            .frame(height:40)
//                        TextField("Portiegrootte", text:$portionAmount)
//                            .multilineTextAlignment(.trailing)
//                            .frame(height:40)
//                            .keyboardType(.numberPad)
//                    }
//                        Button(action:{
//                            var amountNumber: Int = 0
//                            if let value = NumberFormatter().number(from: portionAmount) {
//                                amountNumber = value.intValue
//                            }
//                            self.product.portions.append(ProductPortion(name: portionName, amount:amountNumber))
//                            self.portionName = ""
//                            self.portionAmount = ""
//                            
//                        },label:{
//                            HStack{
//                                Image(systemName:"plus")
//                                Text("Voeg portie toe")
//                            }
//                        })
//                    }
//                Section(header:Text("Nutrienten per 100 gram")){
//                   HStack{
//                    Text("Calorie??n")
//                    TextField($kcalInput.wrappedValue, text: $kcalInput ,onEditingChanged: { _ in
//                        if let value = NumberFormatter().number(from: kcalInput) {
//                            self.product.kcal = value.doubleValue
//                        }
//                        calculateKcal()
//                    })
//                        .multilineTextAlignment(.trailing)
//                        .keyboardType(.decimalPad)
//                    }
//                    HStack{
//                        Text("Koolhydraten (g)")
//                        TextField($carbsInput.wrappedValue, text: $carbsInput ,onEditingChanged: { _ in
//                            if let value = NumberFormatter().number(from: carbsInput) {
//                                self.product.carbs = value.doubleValue
//                            }
//                            calculateKcal()
//                        })
//                        .multilineTextAlignment(.trailing)
//                            .keyboardType(.decimalPad)
//                    }
//                    HStack{
//                        Text("Eiwitten (g)")
//                        TextField($proteinInput.wrappedValue, text: $proteinInput ,onEditingChanged: { _ in
//                            if let value = NumberFormatter().number(from: proteinInput) {
//                                self.product.protein = value.doubleValue
//                            }
//                            calculateKcal()
//                        })
//                        .multilineTextAlignment(.trailing)
//                        .keyboardType(.decimalPad)
//                    }
//                    HStack{
//                        Text("Vetten (g)")
//                        TextField($fatInput.wrappedValue, text: $fatInput ,onEditingChanged: { _ in
//                            if let value = NumberFormatter().number(from: fatInput) {
//                                self.product.fat = value.doubleValue
//                            }
//                            calculateKcal()
//                        })
//                        .multilineTextAlignment(.trailing)
//                        .keyboardType(.decimalPad)
//                    }
//                    HStack{
//                        Text("Vezels (g)")
//                        TextField($fiberInput.wrappedValue, text: $fiberInput ,onEditingChanged: { _ in
//                            if let value = NumberFormatter().number(from: fiberInput) {
//                                self.product.fiber = value.doubleValue
//                            }
//                            calculateKcal()
//                        })
//                        .multilineTextAlignment(.trailing)
//                        .keyboardType(.decimalPad)
//                    }
//                }
//                
//        }.onAppear(perform:{
//            self.kcalInput = String(product.kcal)
//            self.carbsInput = String(product.carbs)
//            self.proteinInput = String(product.protein)
//            self.fatInput = String(product.fat)
//            self.fiberInput = String(product.fiber)
//            })
//            .listStyle(InsetGroupedListStyle())
//            .navigationTitle(Text(self.product.name))
//            .navigationBarItems(trailing:
//                                    Button(action: {
//                                            let success = self.foodModel.createProduct(product: product)
//                                            if success {
//                                            self.showManageProductDetailView = false}
//                                    })
//                                    { Text("Opslaan") }
//                                    .disabled(self.product.name.isEmpty)
//        )}
//    
//    func deletePortion(at offsets: IndexSet) {
//        let index: Int = offsets[offsets.startIndex]
//        self.product.portions.remove(at: index)
//    }
//    
//}
