import SwiftUI
import Foundation
import UIKit

struct SalaryTemplate: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var base: Double
    var factor: Double
    var fixed: Double
    var afterTaxRatio: Double
}

struct ToolsView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case salary
        case recovery

        var id: String { rawValue }
    }

    @State private var activeTool: Tool?

    var body: some View {
        ZStack {
            if let tool = activeTool {
                Group {
                    switch tool {
                    case .salary:
                        SalaryToolView {
                            withAnimation(.snappy(duration: 0.3)) { activeTool = nil }
                        }
                    case .recovery:
                        RecoveryToolView {
                            withAnimation(.snappy(duration: 0.3)) { activeTool = nil }
                        }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .edgeSwipeBack {
                    withAnimation(.snappy(duration: 0.3)) { activeTool = nil }
                }
            } else {
                toolsList
                    .transition(.opacity)
            }
        }
        .animation(.snappy(duration: 0.3), value: activeTool)
    }

    private var toolsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("常用小工具")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.secondary)
                Text("工具")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 0) {
                    toolRow(
                        icon: "function",
                        tint: Theme.accent,
                        title: "工资计算器",
                        subtitle: "绩效 + 固定工资 · 税后实发"
                    ) {
                        withAnimation(.snappy(duration: 0.3)) { activeTool = .salary }
                    }
                    Rectangle()
                        .fill(Theme.secondary.opacity(0.08))
                        .frame(height: 1)
                        .padding(.leading, 64)
                    toolRow(
                        icon: "chart.line.downtrend.xyaxis",
                        tint: Color(hex: 0xF2B544),
                        title: "回本涨幅计算器",
                        subtitle: "亏损后需要涨多少才回本"
                    ) {
                        withAnimation(.snappy(duration: 0.3)) { activeTool = .recovery }
                    }
                }
                .padding(6)
                .glassCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    private func toolRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.13))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SalaryToolView: View {
    @AppStorage("salary.base") private var base: Double = 1000
    @AppStorage("salary.factor") private var factor: Double = 1.5
    @AppStorage("salary.fixed") private var fixed: Double = 1000
    @AppStorage("salary.afterTaxRatio") private var afterTaxRatio: Double = 0.9
    @AppStorage("salary.templates") private var templatesJSON: String = "[]"

    @State private var selectedTemplateID: UUID?
    @State private var showNameAlert = false
    @State private var templateName = ""

    let onBack: () -> Void

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    private var perf: Double { base * factor }
    private var gross: Double { perf + fixed }
    private var net: Double { gross * afterTaxRatio }
    private var taxRate: Double { 1 - afterTaxRatio }

    private var templates: [SalaryTemplate] {
        guard let data = templatesJSON.data(using: .utf8),
              let list = try? JSONDecoder().decode([SalaryTemplate].self, from: data) else {
            return []
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                templateStrip
                resultCard
                paramsCard
                breakdownCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if afterTaxRatio > 1 { afterTaxRatio /= 100 }
        }
        .onChange(of: afterTaxRatio) { _, value in
            afterTaxRatio = clamp(value, 0...1)
        }
        .onChange(of: factor) { _, value in
            factor = clamp(value, 0...10)
        }
        .alert("保存模板", isPresented: $showNameAlert) {
            TextField("模板名称", text: $templateName)
            Button("取消", role: .cancel) {}
            Button("保存") { saveTemplate() }
        } message: {
            Text("将当前参数保存为模板，之后一点即可套用")
        }
        .keyboardDoneButton()
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.white.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回工具")

            Text("工资计算器")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.ink)

            Spacer()

            Button {
                templateName = ""
                showNameAlert = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 11, weight: .semibold))
                    Text("存为模板")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .glassCapsule()
            }
            .buttonStyle(.plain)
        }
    }

    private var templateStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("模板")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Theme.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        newCalculation()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text("新建计算")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.55)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    ForEach(templates) { template in
                        templateChip(template)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func templateChip(_ template: SalaryTemplate) -> some View {
        let selected = template.id == selectedTemplateID
        return HStack(spacing: 6) {
            Button {
                apply(template)
            } label: {
                Text(template.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selected ? Color.white : Theme.ink)
            }
            .buttonStyle(.plain)

            Button {
                remove(template)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : Theme.secondary)
                    .frame(width: 14, height: 14)
                    .background(Circle().fill(.white.opacity(selected ? 0.25 : 0.5)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除模板")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(
                selected
                    ? AnyShapeStyle(Theme.accent.gradient)
                    : AnyShapeStyle(Color.white.opacity(0.55))
            )
        )
        .overlay(
            Capsule().strokeBorder(
                selected ? Color.clear : Color.white.opacity(0.8),
                lineWidth: 1
            )
        )
        .contextMenu {
            Button(role: .destructive) {
                remove(template)
            } label: {
                Label("删除模板", systemImage: "trash")
            }
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("实发工资")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x3D5BD9))
            Text(money(net))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("应发 \(money(gross)) · 扣除 \(money(gross - net))")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.12), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .glassCard()
    }

    private var paramsCard: some View {
        VStack(spacing: 12) {
            paramRow("绩效基数") {
                moneyField($base)
            }
            paramRow("绩效系数") {
                NumberStepperField(value: $factor, step: 0.1, range: 0...10)
            }
            paramRow("固定金额") {
                moneyField($fixed)
            }

            Rectangle()
                .fill(Theme.secondary.opacity(0.12))
                .frame(height: 1)

            paramRow("税后比例") {
                HStack(spacing: 8) {
                    NumberStepperField(value: $afterTaxRatio, step: 0.01, range: 0...1)
                    Text(percentText(afterTaxRatio))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()
                        .frame(minWidth: 38, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassCard()
    }

    private var breakdownCard: some View {
        VStack(spacing: 0) {
            breakdownRow("绩效工资", money(perf))
            breakdownRow("固定工资", money(fixed), divider: true)
            breakdownRow("应发工资", money(gross), divider: true)
            breakdownRow("扣除比例", percentText(taxRate), divider: true)
            breakdownRow("实发工资", money(net), highlighted: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .glassCard()
    }

    private func paramRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            content()
        }
    }

    private func moneyField(_ value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text("¥")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(width: 84)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }

    private func breakdownRow(
        _ label: String,
        _ value: String,
        highlighted: Bool = false,
        divider: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 12.5, weight: highlighted ? .semibold : .regular))
                    .foregroundStyle(highlighted ? Theme.ink : Theme.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: highlighted ? 16 : 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(highlighted ? Theme.accent : Theme.ink)
                    .monospacedDigit()
            }
            .padding(.vertical, 9)
            if divider {
                Rectangle()
                    .fill(Theme.secondary.opacity(0.1))
                    .frame(height: 0.7)
            }
        }
    }

    private func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        let rounded = (value * 1000).rounded() / 1000
        return min(range.upperBound, max(range.lowerBound, rounded))
    }

    private func percentText(_ ratio: Double) -> String {
        let percent = (ratio * 1000).rounded() / 10
        if percent == percent.rounded() {
            return String(format: "%.0f%%", percent)
        }
        return String(format: "%.1f%%", percent)
    }

    private func newCalculation() {
        withAnimation(.snappy(duration: 0.25)) {
            base = 1000
            factor = 1
            fixed = 1000
            afterTaxRatio = 1
            selectedTemplateID = nil
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func apply(_ template: SalaryTemplate) {
        withAnimation(.snappy(duration: 0.25)) {
            base = template.base
            factor = template.factor
            fixed = template.fixed
            afterTaxRatio = template.afterTaxRatio
            selectedTemplateID = template.id
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func remove(_ template: SalaryTemplate) {
        guard let data = templatesJSON.data(using: .utf8),
              let list = try? JSONDecoder().decode([SalaryTemplate].self, from: data) else {
            return
        }
        if selectedTemplateID == template.id { selectedTemplateID = nil }
        persist(list.filter { $0.id != template.id })
    }

    private func saveTemplate() {
        let trimmed = templateName.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "模板 \(templates.count + 1)" : trimmed
        var list = templates
        let template = SalaryTemplate(
            name: name,
            base: base,
            factor: factor,
            fixed: fixed,
            afterTaxRatio: afterTaxRatio
        )
        list.append(template)
        persist(list)
        selectedTemplateID = template.id
    }

    private func persist(_ list: [SalaryTemplate]) {
        if let data = try? JSONEncoder().encode(list),
           let json = String(data: data, encoding: .utf8) {
            templatesJSON = json
        }
    }
}