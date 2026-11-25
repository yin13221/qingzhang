import SwiftUI
import SwiftData
import Foundation

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bill.date, order: .reverse) private var bills: [Bill]
    @Query private var accounts: [Account]
    @Query(sort: \Transfer.date, order: .reverse) private var transfers: [Transfer]

    @State private var filter = BillFilter()
    @State private var period = HomePeriod()
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Int, Identifiable {
        case filter
        case addAccount
        case customPeriod
        var id: Int { rawValue }
    }

    private struct Entry: Identifiable {
        enum Content {
            case bill(Bill)
            case transfer(Transfer)
        }
        let id: String
        let date: Date
        let content: Content
    }

    private struct DayGroup: Identifiable {
        let id: Date
        let entries: [Entry]
        let expense: Decimal
    }

    private let calendar = Calendar.current
    private let dayFormatter = makeDateFormatter("M月d日 · EEE")

    private var sortedAccounts: [Account] {
        accounts.sorted { $0.order < $1.order }
    }

    private var allTags: [String] {
        Array(Set(bills.flatMap { $0.tags })).sorted()
    }

    private var filteredBills: [Bill] {
        bills.filter { bill in
            period.contains(bill.date)
                && filter.matches(
                    bill: bill,
                    categoryTitle: Categories.find(bill.categoryID, in: bill.type).name,
                    accountTitle: accountTitle(bill.accountKey)
                )
        }
    }

    private var filteredTransfers: [Transfer] {
        transfers.filter { transfer in
            period.contains(transfer.date)
                && filter.matches(
                    transfer: transfer,
                    fromTitle: accountTitle(transfer.fromKey),
                    toTitle: accountTitle(transfer.toKey)
                )
        }
    }

    private var entries: [Entry] {
        let billEntries = filteredBills.map { bill in
            Entry(id: "b-" + String(describing: bill.persistentModelID), date: bill.date, content: .bill(bill))
        }
        let transferEntries = filteredTransfers.map { transfer in
            Entry(id: "t-" + String(describing: transfer.persistentModelID), date: transfer.date, content: .transfer(transfer))
        }
        return (billEntries + transferEntries).sorted { $0.date > $1.date }
    }

    private var groups: [DayGroup] {
        let dict = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { day in
            let items = dict[day] ?? []
            let expense = items.reduce(Decimal.zero) { sum, entry in
                if case .bill(let bill) = entry.content, bill.type == .expense {
                    return sum + bill.amount
                }
                return sum
            }
            return DayGroup(id: day, entries: items, expense: expense)
        }
    }

    private var expenseTotal: Decimal {
        filteredBills.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var incomeTotal: Decimal {
        filteredBills.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                if filter.isActive {
                    filterBar
                }
                summaryCard
                AccountsStrip(accounts: sortedAccounts, bills: bills, transfers: transfers) {
                    activeSheet = .addAccount
                }
                billSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .filter:
                FilterSheetView(filter: $filter, accounts: sortedAccounts, tags: allTags)
            case .addAccount:
                AddAccountSheet()
            case .customPeriod:
                CustomPeriodSheet(start: $period.start, end: $period.end) {
                    period.preset = .custom
                }
            }
        }
    }

    private var periodMenu: some View {
        Menu {
            ForEach(HomePeriod.Preset.allCases) { preset in
                Button {
                    if preset == .custom {
                        activeSheet = .customPeriod
                    } else {
                        withAnimation(.snappy(duration: 0.2)) {
                            period.preset = preset
                        }
                    }
                } label: {
                    if period.preset == preset {
                        Label(preset.title, systemImage: "checkmark")
                    } else {
                        Text(preset.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(period.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glassCapsule()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("账本")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            periodMenu
            filterButton
        }
    }

    private var filterButton: some View {
        Button {
            activeSheet = .filter
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.55)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.75), lineWidth: 1))
                if filter.activeCount > 0 {
                    Text("\(filter.activeCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Theme.accent))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("筛选与搜索")
    }

    private var filterBar: some View {
        HStack {
            Text("筛选结果 · \(entries.count) 笔")
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Button("清除") {
                withAnimation(.snappy) { filter = BillFilter() }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.accent)
        }
        .foregroundStyle(Color(hex: 0x3D5BD9))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent.opacity(0.09)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.16), lineWidth: 1)
        )
        .transition(.opacity)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(filter.isActive ? "筛选支出" : period.caption)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.secondary)
            Text(money(expenseTotal))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 12) {
                statItem(label: "收入", value: money(incomeTotal), color: Theme.mint)
                Rectangle()
                    .fill(Theme.secondary.opacity(0.25))
                    .frame(width: 1, height: 22)
                statItem(label: "结余", value: money(incomeTotal - expenseTotal), color: Theme.ink)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    private var billSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("最近账单")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("共 \(entries.count) 笔")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 6)
            if groups.isEmpty {
                emptyState
            } else {
                ForEach(groups) { group in
                    daySection(group)
                }
            }
        }
    }

    private func daySection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dayLabel(group.id))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                if group.expense > 0 {
                    Text("支出 " + money(group.expense))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.secondary.opacity(0.9))
                }
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(group.entries.indices, id: \.self) { index in
                    let entry = group.entries[index]
                    switch entry.content {
                    case .bill(let bill):
                        billRow(bill)
                    case .transfer(let transfer):
                        transferRow(transfer)
                    }
                    if index < group.entries.count - 1 {
                        Rectangle()
                            .fill(Theme.secondary.opacity(0.12))
                            .frame(height: 0.7)
                            .padding(.leading, 58)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 3)
            .glassCard(24)
        }
    }

    private func billRow(_ bill: Bill) -> some View {
        let category = Categories.find(bill.categoryID, in: bill.type)
        let accountName = accountTitle(bill.accountKey)
        let tagText = bill.tags.map { "#" + $0 }.joined(separator: " ")
        let note = [bill.note, tagText].filter { !$0.isEmpty }.joined(separator: " · ")
        return HStack(spacing: 11) {
            iconTile(symbol: category.symbol, color: category.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                if !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text((bill.type == .income ? "+" : "-") + money(bill.amount))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(bill.type == .income ? Theme.mint : Theme.ink)
                    .monospacedDigit()
                Text(accountName)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.snappy) {
                    context.delete(bill)
                    try? context.save()
                }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func transferRow(_ transfer: Transfer) -> some View {
        let route = accountTitle(transfer.fromKey) + " → " + accountTitle(transfer.toKey)
        let note = [route, transfer.note].filter { !$0.isEmpty }.joined(separator: " · ")
        return HStack(spacing: 11) {
            iconTile(symbol: "arrow.left.arrow.right", color: Theme.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("转账")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(money(transfer.amount))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.secondary)
                    .monospacedDigit()
                Text("账户转账")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.snappy) {
                    context.delete(transfer)
                    try? context.save()
                }
            } label: {
                Label("删除转账", systemImage: "trash")
            }
        }
    }

    private func iconTile(symbol: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 38, height: 38)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func accountTitle(_ key: UUID?) -> String {
        guard let key, let account = accounts.first(where: { $0.key == key }) else {
            return "未指定账户"
        }
        return account.name
    }

    private func dayLabel(_ day: Date) -> String {
        let base = dayFormatter.string(from: day)
        if calendar.isDateInToday(day) {
            return "今天 · " + base
        }
        if calendar.isDateInYesterday(day) {
            return "昨天 · " + base
        }
        return base
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: filter.isActive ? "magnifyingglass" : "tray")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.secondary.opacity(0.7))
            Text(filter.isActive ? "没有符合条件的账单" : "还没有账单")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(filter.isActive ? "试试放宽筛选条件" : "点击右下角 + 记下第一笔")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .glassCard()
    }
}