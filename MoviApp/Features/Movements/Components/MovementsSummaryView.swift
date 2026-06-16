import SwiftUI

struct MovementsSummaryView: View {
    let movementCount: Int
    let netAmountText: String
    let creditCount: Int
    let debitCount: Int

    var body: some View {
        VStack(spacing: 8) {
            NetSummaryChip(value: netAmountText)

            HStack(spacing: 8) {
                SummaryMetricChip(
                    title: "Mov.",
                    value: "\(movementCount)",
                    color: Color(.systemIndigo),
                    iconName: "list.bullet.rectangle"
                )

                SummaryMetricChip(
                    title: "Créd.",
                    value: "\(creditCount)",
                    color: Color(.systemGreen),
                    iconName: "arrow.down.left"
                )

                SummaryMetricChip(
                    title: "Déb.",
                    value: "\(debitCount)",
                    color: Color(.systemRed),
                    iconName: "arrow.up.right"
                )
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: movementCount)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: netAmountText)
    }
}

private struct NetSummaryChip: View {
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sum")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 34, height: 34)
                .background(Color(.systemBlue).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Resultado neto")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.systemBlue).opacity(0.16), lineWidth: 1)
        }
    }
}

private struct SummaryMetricChip: View {
    let title: String
    let value: String
    let color: Color
    let iconName: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        }
    }
}
