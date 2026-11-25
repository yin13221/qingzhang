import SwiftUI
import UIKit
import Foundation

struct NumberStepperField: View {
    @Binding var value: Double
    var step: Double
    var range: ClosedRange<Double>
    var width: CGFloat = 62

    var body: some View {
        HStack(spacing: 6) {
            stepButton("−") {
                apply(value - step)
            }
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(width: width)
            stepButton("+") {
                apply(value + step)
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.85)))
        }
        .buttonStyle(.plain)
    }

    private func apply(_ raw: Double) {
        let rounded = (raw * 1000).rounded() / 1000
        value = min(range.upperBound, max(range.lowerBound, rounded))
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct SheetBackground: View {
    var body: some View {
        AuroraBackground()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 40,
                    topTrailingRadius: 40,
                    style: .continuous
                )
            )
            .ignoresSafeArea()
    }
}

struct ChipView: View {
    let title: String
    var dotColor: Color?
    let selected: Bool
    let action: () -> Void

    init(_ title: String, dotColor: Color? = nil, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.dotColor = dotColor
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selected ? Color.white : Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(
                    selected
                        ? AnyShapeStyle(Theme.accent.gradient)
                        : AnyShapeStyle(Color.white.opacity(0.55))
                )
            }
            .overlay {
                Capsule().strokeBorder(
                    selected ? Color.clear : Color.white.opacity(0.75),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.secondary)
            content
        }
    }
}

struct ChipGrid<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 70), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            content
        }
    }
}

struct SwipeDeleteRow<Content: View>: View {
    private let onDelete: () -> Void
    private let onTap: (() -> Void)?
    private let content: Content

    @State private var offset: CGFloat = 0
    @State private var dragBase: CGFloat = 0
    @State private var isDragging = false

    init(onDelete: @escaping () -> Void, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: performDelete) {
                VStack(spacing: 3) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                    Text("删除")
                        .font(.system(size: 10.5, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 78)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0xFF5A5F))
                )
            }
            .buttonStyle(.plain)
            .padding(.vertical, 3)
            .opacity(offset < -6 ? 1 : 0)

            content
                .background(Color(hex: 0xF6F7FB).opacity(0.97))
                .offset(x: offset)
                .simultaneousGesture(dragGesture)
                .onTapGesture {
                    if offset < 0 {
                        close()
                    } else {
                        onTap?()
                    }
                }
        }
        .clipped()
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if !isDragging {
                    isDragging = true
                    dragBase = offset
                }
                offset = min(0, max(-86, dragBase + value.translation.width))
            }
            .onEnded { value in
                isDragging = false
                let shouldOpen = offset < -44 || value.translation.width < -60
                withAnimation(.snappy(duration: 0.22)) {
                    offset = shouldOpen ? -78 : 0
                }
            }
    }

    private func close() {
        withAnimation(.snappy(duration: 0.2)) { offset = 0 }
    }

    private func performDelete() {
        UISelectionFeedbackGenerator().selectionChanged()
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            onDelete()
        }
    }
}

extension View {
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }

    func edgeSwipeBack(_ action: @escaping () -> Void) -> some View {
        modifier(EdgeSwipeBackModifier(action: action))
    }
}

private struct EdgeSwipeBackModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    guard value.startLocation.x < 40,
                          value.translation.width > 80,
                          abs(value.translation.height) < 120 else { return }
                    action()
                }
        )
    }
}