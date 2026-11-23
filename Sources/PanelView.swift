// The whole panel: one light grey glass track with two choices,
// sleep and awake. The current one is a raised white pill. Black icons.

import SwiftUI

private enum Style {
    static let track = Color(white: 0.93).opacity(0.85)
    static let ink = Color.black.opacity(0.86)
    static let inkQuiet = Color.black.opacity(0.32)
}

struct PanelView: View {
    @Bindable var model: AwakeModel
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 2) {
            segment("moon.zzz", selected: !model.isActive, label: "Let your Mac sleep") { model.stop() }
            segment("cup.and.saucer.fill", selected: model.isActive, label: "Keep your Mac awake") { model.start() }
        }
        .padding(3)
        .glassEffect(.regular.tint(Style.track), in: Capsule())
        .padding(8) // clear margin so the glass edge and shadow aren't clipped
        .focusEffectDisabled()
        .animation(.smooth(duration: 0.28), value: model.isActive)
        .environment(\.colorScheme, .light)
    }

    private func segment(_ symbol: String, selected: Bool, label: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? Style.ink : Style.inkQuiet)
                .frame(width: 44, height: 30)
                .background {
                    if selected { Pill().matchedGeometryEffect(id: "pill", in: selection) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The raised white selection, like a lighter piece of glass on the track.
private struct Pill: View {
    var body: some View {
        Capsule()
            .fill(.white)
            .shadow(color: .black.opacity(0.10), radius: 1.5, y: 1)
    }
}
