import SwiftUI

struct SplashScreen: View {
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("menuImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
                
                Text("Grow")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                ProgressView()
                    .controlSize(.regular)
                    .tint(.accentColor)
            }
            .padding(32)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}
