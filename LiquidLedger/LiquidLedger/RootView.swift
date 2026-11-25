import SwiftUI
import UIKit

struct RootView: View {
    enum Tab { case home, stats, tools }

    @Environment(\.modelContext) private var context
    @State private var tab: Tab = .home
    @State private var showingAdd = false
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            AuroraBackground()

            Group {
                switch tab {
                case .home:
                    HomeView()
                case .stats:
                    StatsView()
                case .tools:
                    ToolsView()
                }
            }
            .id(tab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.985)),
                    removal: .opacity
                )
            )

            bottomBar
        }
        .sheet(isPresented: $showingAdd) {
            AddTransactionView()
        }
        .task {
            DefaultData.seedAccountsIfNeeded(context)
        }
        .tint(Theme.accent)
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            tabRow

            Spacer(minLength: 12)

            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.violet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: Theme.accent.opacity(0.45), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("记一笔")
        }
        .padding(.bottom, 10)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var tabRow: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 14) {
                tabCapsule
            }
        } else {
            tabCapsule
        }
    }

    private var tabCapsule: some View {
        HStack(spacing: 2) {
            tabButton(.home, title: "首页", symbol: "house.fill")
            tabButton(.stats, title: "统计", symbol: "chart.pie.fill")
            tabButton(.tools, title: "工具", symbol: "wrench.and.screwdriver.fill")
        }
        .padding(5)
        .glassCard(34)
    }

    private func tabButton(_ value: Tab, title: String, symbol: String) -> some View {
        let selected = tab == value
        return Button {
            guard tab != value else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                tab = value
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 14.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
            }
            .foregroundStyle(selected ? Theme.accent : Theme.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                if selected {
                    glider
                        .matchedGeometryEffect(id: "tabGlider", in: tabNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(TabPressStyle())
    }

    @ViewBuilder
    private var glider: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.white.opacity(0.001))
                .glassEffect(
                    .regular.tint(Theme.accent.opacity(0.16)),
                    in: Capsule()
                )
        } else {
            Capsule()
                .fill(.white.opacity(0.75))
                .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                .shadow(color: Theme.ink.opacity(0.08), radius: 8, y: 4)
        }
    }
}

private struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}