import SwiftUI

struct AppToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: content.iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(content.color)
                .frame(width: 34, height: 34)
                .background(content.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(content.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(content.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar mensaje")
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(content.color.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 10)
    }

    private var content: ToastContent {
        let normalizedMessage = message.lowercased()

        if normalizedMessage.contains("desarchivado") {
            return ToastContent(
                title: "Movimiento desarchivado",
                subtitle: "Volvió a la vista principal.",
                iconName: "tray.and.arrow.up.fill",
                color: Color(.systemGreen)
            )
        }

        if normalizedMessage.contains("archivado") {
            return ToastContent(
                title: "Movimiento archivado",
                subtitle: "Se guardó en Archivados.",
                iconName: "archivebox.fill",
                color: Color(.systemOrange)
            )
        }

        return ToastContent(
            title: "No se pudo completar",
            subtitle: message,
            iconName: "exclamationmark.triangle.fill",
            color: Color(.systemRed)
        )
    }
}

private struct ToastContent {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
}
