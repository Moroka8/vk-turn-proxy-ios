import SwiftUI

struct StateBadge: View {
    let state: ProxyState

    var body: some View {
        Label(state.title, systemImage: iconName)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }

    private var iconName: String {
        switch state {
        case .stopped:
            return "pause.circle"
        case .connecting:
            return "arrow.triangle.2.circlepath"
        case .running:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .stopped:
            return .secondary
        case .connecting:
            return .orange
        case .running:
            return .green
        case .error:
            return .red
        }
    }
}
