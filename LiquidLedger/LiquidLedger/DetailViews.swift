import SwiftUI
import SwiftData
import UIKit

struct BillDetailSheet: View {
    let bill: Bill

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    private let dateFormatter = makeDateFormatter("yyyy年M月d日 HH:mm")

    private var category: TxCategory { Categories.find(bill.categoryID, in: bill.type) }

    private var accountName: String {
        guard let key = bill.accountKey,
              let account = accounts.first(where: { $0.key == key }) else {
            return "未指定账户"
        }
        return account.name
    }

    var body: some View {
        ZStack {
            SheetBackground()

            ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                HStack {
                    Text("账单详情")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    closeButton
                }

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(category.color.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: category.symbol)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(bill.type.title)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondary)
                    }
                    Spacer()
                    Text((bill.type == .income ? "+" : "-") + money(bill.amount))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(bill.type == .income ? Theme.mint : Theme.ink)
                        .monospacedDigit()
                }
                .padding(16)
                .glassCard(22)

                VStack(spacing: 0) {
                    detailRow("账户", accountName)
                    detailRow("时间", dateFormatter.string(from: bill.date), divider: true)
                    if !bill.note.isEmpty {
                        detailRow("备注", bill.note, divider: true)
                    }
                    if !bill.tags.isEmpty {
                        detailRow("标签", bill.tags.map { "#" + $0 }.joined(separator: " "), divider: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .glassCard(20)

                Button(role: .destructive) {
                    deleteBill()
                } label: {
                    Label("删除这笔账单", systemImage: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color(hex: 0xFF5A5F)))
                }
                .buttonStyle(.plain)
            }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
    }

    private var closeButton: some View {
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

    private func detailRow(_ title: String, _ value: String, divider: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondary)
                Spacer(minLength: 20)
                Text(value)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 9)
            if divider {
                Rectangle()
                    .fill(Theme.secondary.opacity(0.1))
                    .frame(height: 0.7)
            }
        }
    }

    private func deleteBill() {
        context.delete(bill)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

struct TransferDetailSheet: View {
    let transfer: Transfer

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    private let dateFormatter = makeDateFormatter("yyyy年M月d日 HH:mm")

    private var fromName: String { name(for: transfer.fromKey) }
    private var toName: String { name(for: transfer.toKey) }

    var body: some View {
        ZStack {
            SheetBackground()

            ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                HStack {
                    Text("转账详情")
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

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Theme.secondary.opacity(0.14))
                            .frame(width: 46, height: 46)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("账户转账")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(fromName + " → " + toName)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(money(transfer.amount))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
                .padding(16)
                .glassCard(22)

                VStack(spacing: 0) {
                    detailRow("转出", fromName)
                    detailRow("转入", toName, divider: true)
                    detailRow("时间", dateFormatter.string(from: transfer.date), divider: true)
                    if !transfer.note.isEmpty {
                        detailRow("备注", transfer.note, divider: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .glassCard(20)

                Button(role: .destructive) {
                    context.delete(transfer)
                    try? context.save()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                } label: {
                    Label("删除这笔转账", systemImage: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color(hex: 0xFF5A5F)))
                }
                .buttonStyle(.plain)
            }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
    }

    private func name(for key: UUID) -> String {
        accounts.first(where: { $0.key == key })?.name ?? "未知账户"
    }

    private func detailRow(_ title: String, _ value: String, divider: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondary)
                Spacer(minLength: 20)
                Text(value)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 9)
            if divider {
                Rectangle()
                    .fill(Theme.secondary.opacity(0.1))
                    .frame(height: 0.7)
            }
        }
    }
}