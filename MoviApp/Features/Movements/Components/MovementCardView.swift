import SwiftUI

struct MovementCardView: View {
    let row: MovementRowViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: row.movement.type.iconName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(row.movement.type.tintColor)
                        .frame(width: 46, height: 46)
                        .background(row.movement.type.softColor, in: RoundedRectangle(cornerRadius: 8))

                    if row.isArchived {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Color(.systemOrange), in: Circle())
                            .offset(x: 4, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(row.movement.personName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(row.movement.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 7) {
                        StatusPill(status: row.movement.status)

                        Text(row.movement.type.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(row.movement.type.tintColor)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(row.amountText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(row.movement.amount < Decimal.zero ? Color(.systemRed) : Color(.systemGreen))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Label(row.timeText, systemImage: "clock")
                Label(row.movement.category, systemImage: "tag")
                Spacer(minLength: 0)
                Text(row.movement.channel)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(row.movement.type.tintColor)
                .frame(width: 4)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct StatusPill: View {
    let status: MovementStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.bold))
            .foregroundStyle(status.tintColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.tintColor.opacity(0.12), in: Capsule())
    }
}
