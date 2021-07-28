//
//  ChatView.swift
//  Grow
//
//  Created by Swen Rolink on 28/07/2021.
//

import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationView{
            VStack{
                Text("Hello, chat!")
            }.navigationTitle(Text("Chat met jouw coach"))
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
