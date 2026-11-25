import SwiftUI
import SwiftData
import Charts
import Foundation

struct StatsView: View {
    @Query private var bills: [Bill]

    @State private var monthStart = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)
    ) ?? .now
    @State private var metric: TxType = .expense

    private let calendar = Calendar.current
    private let monthFormatter = makeDateFormatter("yyyy年M月")

    private struct Slice: Identifiable {
        let id: String
        let name: String
        let color: Color
        let total: Decimal
    }

    private struct MonthStat: Identifiable {
        let id: Date
        let income: Double
        let expense: Double
    }

    private var monthBills: [Bill] {
        bills.filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
    }

    private var expenseTotal: Decimal {
        monthBills.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var incomeTotal: Decimal {
        monthBills.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var metricTotal: Decimal {
        metric == .expense ? expenseTotal : incomeTotal
    }

    private var slices: [Slice] {
        var totals: [String: Decimal] = [:]
        for bill in monthBills where bill.type == metric {
            totals[bill.categoryID, default: 0] += bill.amount
        }
        return totals.map { id, total in
            let category = Categories.find(id, in: metric)
            return Slice(id: id, name: category.name, color: category.color, total: total)
        }
        .sorted { $0.total > $1.total }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(monthStart, equalTo: .now, toGranularity: .month)
    }

    private var trend: [MonthStat] {
        (0..<6).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: monthStart) else { return nil }
            let items = bills.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            let income = items.filter { $0.type == .income }.reduce(Decimal.zero) { $0 + $1.amount }
            let expense = items.filter { $0.type == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
            return MonthStat(id: month, income: income.asDouble, expense: expense.asDouble)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsSummary
                donutCard
                trendCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("统计")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 12) {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(PressScaleStyle(scale: 0.85))

                Text(monthFormatter.string(from: monthStart))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 88)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.3), value: monthStart)

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isCurrentMonth ? Theme.secondary.opacity(0.4) : Theme.ink)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(PressScaleStyle(scale: 0.85))
                .disabled(isCurrentMonth)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .glassCapsule()
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 6) {
            Text("支出")
                .foregroundStyle(Theme.secondary)
            Text(money(expenseTotal))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Circle()
                .fill(Theme.secondary.opacity(0.3))
                .frame(width: 3, height: 3)
                .padding(.horizontal, 4)
            Text("收入")
                .foregroundStyle(Theme.secondary)
            Text(money(incomeTotal))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.mint)
                .monospacedDigit()
        }
        .font(.system(size: 12))
        .padding(.leading, 4)
        .padding(.top, -6)
    }

    private var donutCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("分类构成")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                metricSwitch
            }

            if slices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Theme.secondary.opacity(0.6))
                    Text(metric == .expense ? "本月暂无支出" : "本月暂无收入")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
            } else {
                ZStack {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("金额", slice.total.asDouble),
                            innerRadius: .ratio(0.68),
                            angularInset: 3
                        )
                        .cornerRadius(6)
                        .foregroundStyle(slice.color)
                    }
                    .chartLegend(.hidden)
                    .frame(height: 200)

                    VStack(spacing: 3) {
                        Text("总" + metric.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                        Text(money(metricTotal))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    ForEach(slices) { slice in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 8, height: 8)
                            Text(slice.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Text(metric.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(.white.opacity(0.55)))
                                .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))
                            Spacer()
                            Text(percentText(slice))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.secondary)
                                .monospacedDigit()
                            Text(money(slice.total))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .monospacedDigit()
                                .frame(minWidth: 76, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(22)
        .glassCard()
    }

    private var metricSwitch: some View {
        HStack(spacing: 2) {
            ForEach(TxType.allCases) { type in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { metric = type }
                } label: {
                    Text(type.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(metric == type ? Color.white : Theme.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background {
                            if metric == type {
                                Capsule().fill(
                                    type == .expense
                                        ? AnyShapeStyle(Theme.accent)
                                        : AnyShapeStyle(Theme.mint)
                                )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(.white.opacity(0.5)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.7), lineWidth: 1))
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("近 6 个月收支")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Theme.accent).frame(width: 6, height: 6)
                    Text("支出").font(.system(size: 10)).foregroundStyle(Theme.secondary)
                    Circle().fill(Theme.mint).frame(width: 6, height: 6).padding(.leading, 6)
                    Text("收入").font(.system(size: 10)).foregroundStyle(Theme.secondary)
                }
            }

            Chart {
                ForEach(trend) { stat in
                    BarMark(
                        x: .value("月份", stat.id, unit: .month),
                        y: .value("金额", stat.expense)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .position(by: .value("类型", "支出"))

                    BarMark(
                        x: .value("月份", stat.id, unit: .month),
                        y: .value("金额", stat.income)
                    )
                    .foregroundStyle(Theme.mint.gradient)
                    .cornerRadius(5)
                    .position(by: .value("类型", "收入"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.defaultDigits), centered: true)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 170)
        }
        .padding(22)
        .glassCard()
    }

    private func percentText(_ slice: Slice) -> String {
        guard metricTotal > 0 else { return "0%" }
        let ratio = slice.total.asDouble / metricTotal.asDouble * 100
        return String(format: "%.0f%%", ratio)
    }

    private func shiftMonth(_ value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: monthStart) else { return }
        if value > 0, next > .now { return }
        withAnimation(.snappy(duration: 0.25)) {
            monthStart = next
        }
    }
}