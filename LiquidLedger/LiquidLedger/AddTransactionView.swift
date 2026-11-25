import SwiftUI
import SwiftData
import Foundation
import UIKit

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    enum Mode: String, CaseIterable, Identifiable {
        case expense
        case income
        case transfer

        var id: String { rawValue }
        var title: String {
            switch self {
            case .expense: return "支出"
            case .income: return "收入"
            case .transfer: return "转账"
            }
        }
    }

    @State private var mode: Mode = .expense
    @State private var amountText = ""
    @State private var categoryID = Categories.expense[0].id
    @State private var accountKey: UUID?
    @State private var fromKey: UUID?
    @State private var toKey: UUID?
    @State private var note = ""
    @State private var tagText = ""
    @State private var date = Date.now

    private let keyRows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    private var sortedAccounts: [Account] {
        accounts.sorted { $0.order < $1.order }
    }

    private var amount: Decimal? {
        guard let value = Decimal(string: amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        guard amount != nil else { return false }
        if mode == .transfer {
            guard let fromKey, let toKey else { return false }
            return fromKey != toKey
        }
        return true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SheetBackground()

            VStack(spacing: 10) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                modeSwitch

                amountView

                ScrollView {
                    VStack(spacing: 12) {
                        if mode == .transfer {
                            transferPickers
                        } else {
                            categoryGrid
                            accountPicker
                        }
                        noteRow
                        if mode != .transfer {
                            tagRow
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 2)
                    .padding(.bottom, 6)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

                keypad
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
        .onAppear(perform: prepareAccounts)
        .keyboardDoneButton()
    }

    private func prepareAccounts() {
        guard !sortedAccounts.isEmpty else { return }
        if accountKey == nil { accountKey = sortedAccounts[0].key }
        if fromKey == nil { fromKey = sortedAccounts[0].key }
        if toKey == nil {
            toKey = sortedAccounts.dropFirst().first?.key ?? sortedAccounts[0].key
        }
    }

    private var modeSwitch: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        mode = option
                        if option != .transfer {
                            categoryID = Categories.list(for: option == .income ? .income : .expense)[0].id
                        }
                    }
                } label: {
                    Text(option.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(mode == option ? .white : Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if mode == option {
                                Capsule().fill(Theme.accent.gradient)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))
        .padding(.horizontal, 34)
    }

    private var amountView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("¥")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.secondary)
            Text(amountText.isEmpty ? "0" : amountText)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
        }
        .padding(.horizontal, 6)
    }

    private var categoryGrid: some View {
        let type: TxType = mode == .income ? .income : .expense
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
            spacing: 10
        ) {
            ForEach(Categories.list(for: type)) { cat in
                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        categoryID = cat.id
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(categoryID == cat.id ? AnyShapeStyle(cat.color) : AnyShapeStyle(cat.color.opacity(0.14)))
                                .frame(width: 42, height: 42)
                                .shadow(color: categoryID == cat.id ? cat.color.opacity(0.35) : .clear, radius: 10, y: 5)
                            Image(systemName: cat.symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(categoryID == cat.id ? .white : cat.color)
                        }
                        Text(cat.name)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(categoryID == cat.id ? Theme.ink : Theme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            pickerLabel("账户")
            chipScroll { account in
                ChipView(account.name, dotColor: account.kind.color, selected: accountKey == account.key) {
                    accountKey = account.key
                }
            }
        }
    }

    private var transferPickers: some View {
        VStack(alignment: .leading, spacing: 10) {
            pickerLabel("转出")
            chipScroll { account in
                ChipView(account.name, dotColor: account.kind.color, selected: fromKey == account.key) {
                    fromKey = account.key
                    if fromKey == toKey, let alternative = sortedAccounts.first(where: { $0.key != fromKey }) {
                        toKey = alternative.key
                    }
                }
            }
            pickerLabel("转入")
            chipScroll { account in
                ChipView(account.name, dotColor: account.kind.color, selected: toKey == account.key) {
                    toKey = account.key
                    if toKey == fromKey, let alternative = sortedAccounts.first(where: { $0.key != toKey }) {
                        fromKey = alternative.key
                    }
                }
            }
        }
    }

    private func pickerLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(Theme.secondary)
    }

    private func chipScroll<Content: View>(@ViewBuilder content: @escaping (Account) -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sortedAccounts) { account in
                    content(account)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var noteRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondary)
                TextField("添加备注...", text: $note)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.ink)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(Capsule().fill(.white.opacity(0.55)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))

            DatePicker("", selection: $date, in: ...Date.now, displayedComponents: .date)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }

    private var tagRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag")
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondary)
            TextField("标签，空格分隔，如 工作餐", text: $tagText)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))
    }

    private var keypad: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(keyRows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { key in
                            keyButton(key)
                        }
                    }
                }
            }

            Button(action: save) {
                VStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                    Text("保存")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 84)
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.violet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Theme.accent.opacity(canSave ? 0.35 : 0), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.45)
        }
    }

    private func keyButton(_ key: String) -> some View {
        Button {
            press(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 18, weight: .medium))
                } else {
                    Text(key)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(KeyPressStyle())
    }

    private func press(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch key {
        case "⌫":
            if !amountText.isEmpty {
                amountText.removeLast()
            }
        case ".":
            if !amountText.contains(".") {
                amountText = amountText.isEmpty ? "0." : amountText + "."
            }
        default:
            if amountText.count >= 9 { return }
            if let dot = amountText.firstIndex(of: "."),
               amountText.distance(from: dot, to: amountText.endIndex) > 2 {
                return
            }
            amountText = amountText == "0" ? key : amountText + key
        }
    }

    private func save() {
        guard let amount else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagText
            .components(separatedBy: CharacterSet(charactersIn: " ,，"))
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " #")) }
            .filter { !$0.isEmpty }
            .prefix(5)

        if mode == .transfer {
            guard let fromKey, let toKey, fromKey != toKey else { return }
            context.insert(
                Transfer(
                    fromKey: fromKey,
                    toKey: toKey,
                    amount: amount,
                    note: trimmedNote,
                    date: date
                )
            )
        } else {
            context.insert(
                Bill(
                    amount: amount,
                    type: mode == .income ? .income : .expense,
                    categoryID: categoryID,
                    note: trimmedNote,
                    date: date,
                    accountKey: accountKey,
                    tags: Array(tags)
                )
            )
        }
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}