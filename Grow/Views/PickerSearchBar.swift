//
//  PickerSearchBar.swift
//  Grow
//
//  Created by Swen Rolink on 25/02/2022.
//

import SwiftUI

struct PickerSearchBar: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: UIViewRepresentableContext<PickerSearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator

        searchBar.placeholder = placeholder
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .search
        searchBar.enablesReturnKeyAutomatically = false

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        ]
        searchBar.searchTextField.inputAccessoryView = toolbar
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<PickerSearchBar>) {
        uiView.text = text
    }

    func makeCoordinator() -> PickerSearchBar.Coordinator {
        return Coordinator(text: $text, onSubmit: onSubmit)
    }

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String
        let onSubmit: (() -> Void)?

        init(text: Binding<String>, onSubmit: (() -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            onSubmit?()
            searchBar.resignFirstResponder()
        }

        @objc
        func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
