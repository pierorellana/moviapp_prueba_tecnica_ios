import SwiftUI

struct ArchiveFilterTabs: View {
    @Binding var selection: ArchiveFilter

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ArchiveFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    Text(filter.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == filter ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selection == filter ? Color(.systemBlue) : Color.clear)
                )
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
