import SwiftUI

/// Segment kontrolü (implementation.md §4.8). Seçili thumb `matchedGeometryEffect` ile kayar.
struct EchoSegmentedControl<Value: Hashable>: View {
    private let options: [Option]
    @Binding private var selection: Value
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Option: Identifiable {
        let value: Value
        let title: String
        var id: Value { value }

        init(_ value: Value, _ title: String) {
            self.value = value
            self.title = title
        }
    }

    init(selection: Binding<Value>, options: [Option]) {
        _selection = selection
        self.options = options
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in

                Button {
                    withAnimation(AppTheme.motion.resolved(AppTheme.motion.snappy, reduceMotion: reduceMotion)) {
                        selection = option.value
                    }
                } label: {
                    Text(option.title)
                        .echoTextStyle(.subhead)
                        .foregroundStyle(selection == option.value ? AppTheme.color.content.primary : AppTheme.color.content.secondary)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if selection == option.value {

                                Capsule()
                                    .fill(AppTheme.color.bg.surface)
                                    .matchedGeometryEffect(id: "echo.segment.thumb", in: namespace)
                                    .echoSurface(.level1, in: Capsule())
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option.value ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(AppTheme.color.bg.surfaceSunken))
    }
}

#Preview("Segment") {
    @Previewable @State var period = 7

    return EchoSegmentedControl(selection: $period, options: [
        .init(7, "7 gün"), .init(30, "30 gün"), .init(90, "90 gün")
    ])
    .padding()
    .background(AppTheme.color.bg.canvas)
}
