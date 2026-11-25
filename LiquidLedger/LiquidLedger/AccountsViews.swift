import SwiftUI
import SwiftData
import Foundation

struct AccountsStrip: View {
    let accounts: [Account]
    let bills: [Bill]
    let transfers: [Transfer]
    let onAdd: () -> Void

    private var net: Decimal {
        accounts.reduce(Decimal.zero) {
            $0 + accountBalance($1, bills: bills, transfers: transfers)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("账户")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("净资产 " + money(net))
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accounts) { account in
                        card(account)
                    }
                    addCard
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            }
        }
    }

    private func card(_ account: Account) -> some View {
        let balance = accountBalance(account, bills: bills, transfers: transfers)
        return HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(account.kind.color.opacity(0.16))
                    .frame(width: 26, height: 26)
                Image(systemName: account.kind.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(account.kind.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(account.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(money(balance))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(balance < 0 ? Color(hex: 0xFF6470) : Theme.ink)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(width: 128, alignment: .leading)
        .glassCard(16)
    }

    private var addCard: some View {
        Button(action: onAdd) {
            HStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.accent.opacity(0.13))
                        .frame(width: 26, height: 26)
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("添加账户")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("现金 / 银行卡")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(width: 128, alignment: .leading)
            .glassCard(16)
        }
        .buttonStyle(.plain)
    }
}

struct AddAccountSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @State private var name = ""
    @State private var kind: AccountKind = .cash
    @State private var initialText = ""

    var body: some View {
        ZStack {
            SheetBackground()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                HStack {
                    Text("添加账户")
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondary)
                            TextField("账户名称，如：招商银行", text: $name)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(.white.opacity(0.55)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))

                        Text("类型")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.secondary)

                        ChipGrid {
                            ForEach(AccountKind.allCases) { option in
                                ChipView(option.title, dotColor: option.color, selected: kind == option) {
                                    kind = option
                                }
                            }
                        }

                        Text("初始余额")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.secondary)

                        TextField("0.00", text: $initialText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.white.opacity(0.55)))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
                    }
                    .padding(.top, 2)
                }
                .scrollIndicators(.hidden)

                Button(action: save) {
                    Text("保存账户")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
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
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let initial = Decimal(string: initialText.trimmingCharacters(in: .whitespaces)) ?? 0
        let account = Account(
            name: trimmed.isEmpty ? kind.title : trimmed,
            kind: kind,
            initialBalance: initial,
            order: accounts.count
        )
        context.insert(account)
        try? context.save()
        dismiss()
    }
}