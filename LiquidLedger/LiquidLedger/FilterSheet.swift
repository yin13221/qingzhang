import SwiftUI
import SwiftData
import Foundation

struct BillFilter {
    var categories: Set<String> = []
    var accountKeys: Set<UUID> = []
    var minText: String = ""
    var maxText: String = ""
    var keyword: String = ""
    var tags: Set<String> = []

    var isActive: Bool {
        !categories.isEmpty
            || !accountKeys.isEmpty
            || !minText.isEmpty
            || !maxText.isEmpty
            || !keyword.trimmingCharacters(in: .whitespaces).isEmpty
            || !tags.isEmpty
    }

    var activeCount: Int {
        var count = 0
        if !categories.isEmpty { count += 1 }
        if !accountKeys.isEmpty { count += 1 }
        if !minText.isEmpty || !maxText.isEmpty { count += 1 }
        if !keyword.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !tags.isEmpty { count += 1 }
        return count
    }

    func matches(bill: Bill, categoryTitle: String, accountTitle: String) -> Bool {
        guard matchesAmount(bill.amount) else { return false }
        if !categories.isEmpty && !categories.contains(bill.categoryID) { return false }
        if !accountKeys.isEmpty {
            guard let key = bill.accountKey, accountKeys.contains(key) else { return false }
        }
        if !tags.isEmpty && !bill.tags.contains(where: { tags.contains($0) }) { return false }
        return matchesKeyword([bill.note, categoryTitle, accountTitle] + bill.tags)
    }

    func matches(transfer: Transfer, fromTitle: String, toTitle: String) -> Bool {
        guard categories.isEmpty, tags.isEmpty else { return false }
        guard matchesAmount(transfer.amount) else { return false }
        if !accountKeys.isEmpty,
           !accountKeys.contains(transfer.fromKey),
           !accountKeys.contains(transfer.toKey) {
            return false
        }
        return matchesKeyword([transfer.note, fromTitle, toTitle])
    }

    private var minAmount: Decimal? {
        let text = minText.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : Decimal(string: text)
    }

    private var maxAmount: Decimal? {
        let text = maxText.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : Decimal(string: text)
    }

    private func matchesAmount(_ amount: Decimal) -> Bool {
        if let minAmount, amount < minAmount { return false }
        if let maxAmount, amount > maxAmount { return false }
        return true
    }

    private func matchesKeyword(_ parts: [String]) -> Bool {
        let query = keyword.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return true }
        return parts.contains { $0.lowercased().contains(query) }
    }
}

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: BillFilter
    let accounts: [Account]
    let tags: [String]

    @State private var draft = BillFilter()

    var body: some View {
        ZStack {
            SheetBackground()

            VStack(spacing: 12) {
                Capsule()
                    .fill(Theme.ink.opacity(0.15))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        keywordField
                        categorySection
                        accountSection
                        amountSection
                        tagSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)

                actions
                    .padding(.horizontal, 22)
                    .padding(.bottom, 26)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(.clear)
        .onAppear { draft = filter }
    }

    private var header: some View {
        HStack {
            Text("筛选与搜索")
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
        .padding(.horizontal, 22)
    }

    private var keywordField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondary)
            TextField("搜索备注、标签、分类或账户…", text: $draft.keyword)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }

    private var categorySection: some View {
        FilterSection(title: "分类") {
            VStack(alignment: .leading, spacing: 10) {
                chipGroupLabel("支出")
                ChipGrid {
                    ForEach(Categories.expense) { category in
                        ChipView(category.name, dotColor: category.color, selected: draft.categories.contains(category.id)) {
                            if draft.categories.contains(category.id) {
                                draft.categories.remove(category.id)
                            } else {
                                draft.categories.insert(category.id)
                            }
                        }
                    }
                }
                chipGroupLabel("收入")
                ChipGrid {
                    ForEach(Categories.income) { category in
                        ChipView(category.name, dotColor: category.color, selected: draft.categories.contains(category.id)) {
                            if draft.categories.contains(category.id) {
                                draft.categories.remove(category.id)
                            } else {
                                draft.categories.insert(category.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        FilterSection(title: "账户") {
            ChipGrid {
                ForEach(accounts.sorted { $0.order < $1.order }) { account in
                    ChipView(account.name, dotColor: account.kind.color, selected: draft.accountKeys.contains(account.key)) {
                        if draft.accountKeys.contains(account.key) {
                            draft.accountKeys.remove(account.key)
                        } else {
                            draft.accountKeys.insert(account.key)
                        }
                    }
                }
            }
        }
    }

    private var amountSection: some View {
        FilterSection(title: "金额区间") {
            HStack(spacing: 8) {
                amountField("最低", text: $draft.minText)
                Text("—")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondary)
                amountField("最高", text: $draft.maxText)
            }
        }
    }

    private var tagSection: some View {
        FilterSection(title: "标签") {
            if tags.isEmpty {
                Text("还没有使用过标签")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
            } else {
                ChipGrid {
                    ForEach(tags, id: \.self) { tag in
                        ChipView("#" + tag, selected: draft.tags.contains(tag)) {
                            if draft.tags.contains(tag) {
                                draft.tags.remove(tag)
                            } else {
                                draft.tags.insert(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                draft = BillFilter()
            } label: {
                Text("重置")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Capsule().fill(.white.opacity(0.55)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                filter = draft
                dismiss()
            } label: {
                Text("查看结果")
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
    }

    private func chipGroupLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(Theme.secondary)
            .opacity(0.85)
    }

    private func amountField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .font(.system(size: 13))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Capsule().fill(.white.opacity(0.55)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }
}