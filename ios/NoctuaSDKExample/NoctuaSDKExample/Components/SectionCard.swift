import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var expandedByDefault: Bool = true
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool = true

    init(
        title: String,
        icon: String,
        iconColor: Color,
        expandedByDefault: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.expandedByDefault = expandedByDefault
        self.content = content
        self._isExpanded = State(initialValue: expandedByDefault)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                        .frame(width: 28, height: 28)
                        .background(iconColor.opacity(0.15))
                        .cornerRadius(6)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)

                VStack(spacing: 8) {
                    content()
                }
                .padding(12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}
