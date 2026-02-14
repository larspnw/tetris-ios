import SwiftUI

/// App icon view with L-shaped tetromino and "Lars" text
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // L-shaped tetromino
            LShapeView()
                .offset(x: -10, y: 5)
            
            // "Lars" text flowing across the L shape
            Text("Lars")
                .font(.custom("BrushScriptMT", size: 72))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                .rotationEffect(.degrees(-15))
                .offset(x: 5, y: -15)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 180))
    }
}

/// L-shaped tetromino (orange piece)
struct LShapeView: View {
    private let blockSize: CGFloat = 140
    private let cornerRadius: CGFloat = 24
    private let orangeColor = Color(red: 1.0, green: 0.55, blue: 0.1)
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row with single block
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(orangeColor)
                    .frame(width: blockSize, height: blockSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(8)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 4, y: 6)
                
                Spacer()
                    .frame(width: blockSize + 8)
            }
            
            // Bottom row with three blocks
            HStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(orangeColor)
                        .frame(width: blockSize, height: blockSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(8)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 4, y: 6)
                }
            }
        }
        .rotationEffect(.degrees(15))
    }
}

#Preview {
    AppIconView()
}