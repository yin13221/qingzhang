import SwiftUI
import Foundation
import UIKit

struct RecoveryToolView: View {
    @AppStorage("recovery.loss") private var lossPercent: Double = 20

    let onBack: () -> Void

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    private var gain: Double? {
        guard lossPercent < 100 else { return nil }
        return lossPercent / (100 - lossPercent) * 100
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                resultCard
                inputCard
                referenceCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .onChange(of: lossPercent) { _, value in
            lossPercent = min(99.999, max(0, (value * 1000).rounded() / 1000))
        }
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

            Text("回本涨幅计算器")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.ink)

            Spacer()
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("回本所需涨幅")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x3D5BD9))

            if let gain {
                Text(percentText(gain))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("亏损 \(percentText(lossPercent)) 后，需上涨 \(percentText(gain)) 才回本")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondary)
            } else {
                Text("无法回本")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.secondary)
                Text("亏损 100% 及以上无法通过上涨回本")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondary)
            }
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

    private var inputCard: some View {
        HStack {
            Text("亏损百分比")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 8) {
                NumberStepperField(value: $lossPercent, step: 1, range: 0...99.999)
                Text("%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(minWidth: 14)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassCard()
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("常见亏损参考")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.secondary)
                .padding(.top, 6)
                .padding(.bottom, 4)

            ForEach(referenceLosses, id: \.self) { item in
                referenceRow(item)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .glassCard()
    }

    private var referenceLosses: [Double] {
        [10, 20, 30, 50, 70, 90]
    }

    private func referenceRow(_ item: Double) -> some View {
        let needed = item / (100 - item) * 100
        return VStack(spacing: 0) {
            HStack {
                Text("亏损 \(percentText(item))")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("需上涨 \(percentText(needed))")
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            .padding(.vertical, 9)

            if item != referenceLosses.last {
                Rectangle()
                    .fill(Theme.secondary.opacity(0.1))
                    .frame(height: 0.7)
            }
        }
    }

    private func percentText(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(format: "%.0f%%", rounded)
        }
        let timesTen = rounded * 10
        if abs(timesTen - timesTen.rounded()) < 1e-9 {
            return String(format: "%.1f%%", rounded)
        }
        return String(format: "%.2f%%", rounded)
    }
}