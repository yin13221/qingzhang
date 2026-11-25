import SwiftUI
import Foundation

struct HomePeriod {
    enum Preset: String, CaseIterable, Identifiable {
        case today
        case threeDays
        case oneMonth
        case halfYear
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .today: return "今天"
            case .threeDays: return "最近三天"
            case .oneMonth: return "最近一个月"
            case .halfYear: return "最近半年"
            case .custom: return "自定义时间"
            }
        }
    }

    var preset: Preset = .oneMonth
    var start: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    var end: Date = .now

    private static let shortFormatter = makeDateFormatter("M月d日")

    private var bounds: (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date.now
        switch preset {
        case .today:
            return (calendar.startOfDay(for: now), nil)
        case .threeDays:
            return (calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now)), nil)
        case .oneMonth:
            return (calendar.date(byAdding: .month, value: -1, to: now), nil)
        case .halfYear:
            return (calendar.date(byAdding: .month, value: -6, to: now), nil)
        case .custom:
            let start = calendar.startOfDay(for: self.start)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: self.end))
            return (start, end)
        }
    }

    func contains(_ date: Date) -> Bool {
        let bounds = bounds
        if let start = bounds.start, date < start { return false }
        if let end = bounds.end, date >= end { return false }
        return true
    }

    var label: String {
        if preset == .custom {
            return Self.shortFormatter.string(from: start) + " – " + Self.shortFormatter.string(from: end)
        }
        return preset.title
    }

    var caption: String {
        switch preset {
        case .today: return "今日支出"
        case .threeDays: return "近3天支出"
        case .oneMonth: return "近30天支出"
        case .halfYear: return "近半年支出"
        case .custom: return "所选时段支出"
        }
    }
}

struct CustomPeriodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var start: Date
    @Binding var end: Date
    let onApply: () -> Void

    @State private var draftStart = Date.now
    @State private var draftEnd = Date.now

    var body: some View {
        ZStack {
            SheetBackground()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                HStack {
                    Text("自定义时间")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.white.opacity(0.6)))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 12) {
                    row(title: "开始", selection: $draftStart)
                    row(title: "结束", selection: $draftEnd)
                }

                Button {
                    start = min(draftStart, draftEnd)
                    end = max(draftStart, draftEnd)
                    onApply()
                    dismiss()
                } label: {
                    Text("应用")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.violet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .shadow(color: Theme.accent.opacity(0.4), radius: 14, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
        .onAppear {
            draftStart = start
            draftEnd = end
        }
    }

    private func row(title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.secondary)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }
}