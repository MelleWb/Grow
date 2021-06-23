//
//  SwiftUIView.swift
//  Pods
//
//  Created by Swen Rolink on 22/06/2021.
//

import SwiftUI

struct UpdateProfile: View {
    
    @State var displayName:String
    
    var body: some View {
        VStack{
            DisplayName(displayName: $displayName)
            Spacer()
        }.padding()
    }
}

struct DisplayName : View {
    @Binding var displayName: String
    var body: some View {
        return TextField("Displaynaam", text: $displayName)
                .padding()
                .background(Color.init("lightGrey"))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
    }
}

struct UpdateProfile_Previews: PreviewProvider {
    static var previews: some View {
        UpdateProfile(displayName: "")
    }
}
