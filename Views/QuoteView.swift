import SwiftUI

/// Displays an inspirational quote (shown on the menu and between games).
struct QuoteView: View {
    let quote: Quote
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 10) {
            Text("“\(quote.text)”")
                .font(.system(compact ? .subheadline : .body, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(quote.author)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.cyan.opacity(0.8))
        }
        .padding(.horizontal, 24)
    }
}
