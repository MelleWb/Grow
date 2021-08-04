import SwiftUI
import Combine


struct KeyboardProperty {
   var currentHeight: CGFloat = 0
   var animationDuration: Double = 0
    //keyboard notification also gives UIKeyboardAnimationCurveUserInfoKey using which we can completly sync keyboard animation with Scrollview move but In SwiftUI I cannot find any way to use the same.
}

struct AdaptsKeyboard: ViewModifier {

    @State var keyboardProperty: KeyboardProperty = KeyboardProperty()
    func body(content: Content) -> some View {
        content
            .padding(.bottom, self.keyboardProperty.currentHeight)
            .edgesIgnoringSafeArea(self.keyboardProperty.currentHeight == 0 ? Edge.Set() : .bottom)
            .animation(self.keyboardProperty.currentHeight == 0 ?
                       .easeOut(duration: self.keyboardProperty.animationDuration) :
                       .easeIn(duration: self.keyboardProperty.animationDuration))
            .onAppear(perform: subscribeToKeyboardEvents)
            
    }

    private let keyboardWillOpen = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map {
            KeyboardProperty(currentHeight: ($0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect).height,
                             animationDuration: ($0.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
            
        }

    private let keyboardWillHide =  NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map { KeyboardProperty(currentHeight: CGFloat.zero,
        animationDuration: ($0.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)) }

    private func subscribeToKeyboardEvents() {
        _ = Publishers.Merge(keyboardWillOpen, keyboardWillHide)
            .subscribe(on: RunLoop.main)
            .assign(to: \.self.keyboardProperty, on: self)
    }
}
