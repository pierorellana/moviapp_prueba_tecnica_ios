import SwiftUI

struct MovementsHeaderView: View {
    let selectedRange: MovementDateRange
    let onRangeSelected: (MovementDateRange) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Gestión")
                .font(.system(size: 30, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                ForEach(MovementDateRange.allCases) { range in
                    Button {
                        onRangeSelected(range)
                    } label: {
                        Label(range.title, systemImage: selectedRange == range ? "checkmark" : "calendar")
                    }
                }
            } label: {
                Label(selectedRange.title, systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBlue))
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color(.systemBlue).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rango de fechas")
        }
    }
}
