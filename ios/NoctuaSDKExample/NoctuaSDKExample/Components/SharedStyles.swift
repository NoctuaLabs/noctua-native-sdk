import SwiftUI

/// Shared button style used across all section components.
func actionButtonLabel(_ text: String, color: Color = .gray) -> some View {
    Text(text)
        .font(.system(size: 14))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(8)
}
