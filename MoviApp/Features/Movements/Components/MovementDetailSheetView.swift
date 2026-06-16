import SwiftUI

struct MovementDetailSheetView: View {
    let state: MovementDetailViewState
    let onDismiss: () -> Void
    let onRetry: () -> Void
    let onToggleArchive: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                content
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Label("Detalle", systemImage: "doc.text.magnifyingglass")
                        .font(.headline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cerrar detalle")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading(let row):
            loadingContent(row)
        case .loaded(let row):
            detailContent(row)
        case .error(let row, let message):
            errorContent(row: row, message: message)
        }
    }

    private func loadingContent(_ row: MovementRowViewState) -> some View {
        VStack(spacing: 18) {
            MovementDetailHero(row: row, isLoading: true)

            ProgressView()
                .controlSize(.large)
                .tint(Color(.systemBlue))

            Text("Consultando el detalle del movimiento")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func errorContent(row: MovementRowViewState, message: String) -> some View {
        VStack(spacing: 18) {
            MovementDetailHero(row: row, isLoading: false)

            AppStateView(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo cargar el detalle",
                message: message,
                actionTitle: "Reintentar",
                action: onRetry
            )
        }
        .padding(20)
    }

    private func detailContent(_ row: MovementRowViewState) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                MovementDetailHero(row: row, isLoading: false)

                VStack(spacing: 10) {
                    DetailInfoRow(iconName: "person.fill", title: "Persona", value: row.movement.personName)
                    DetailInfoRow(iconName: "text.alignleft", title: "Descripción", value: row.movement.description)
                    DetailInfoRow(iconName: "number", title: "Referencia", value: row.movement.reference)
                    DetailInfoRow(iconName: "calendar", title: "Fecha de transacción", value: MovementFormatters.fullDateTime(row.movement.transactionDate))

                    if let createdAt = row.movement.createdAt {
                        DetailInfoRow(iconName: "clock.badge.checkmark", title: "Creado", value: MovementFormatters.fullDateTime(createdAt))
                    }

                    DetailInfoRow(iconName: "tag.fill", title: "Categoría", value: row.movement.category)
                    DetailInfoRow(iconName: "iphone", title: "Canal", value: row.movement.channel)

                    if let accountId = row.movement.accountId {
                        DetailInfoRow(iconName: "creditcard.fill", title: "Cuenta", value: accountId.uuidString)
                    }

                    DetailInfoRow(iconName: "key.fill", title: "ID movimiento", value: row.id.uuidString)
                }

                Button(action: onToggleArchive) {
                    Label(
                        row.isArchived ? "Desarchivar movimiento" : "Archivar movimiento",
                        systemImage: row.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(row.isArchived ? Color(.systemGreen) : Color(.systemOrange), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, 18)
        }
    }
}

private struct MovementDetailHero: View {
    let row: MovementRowViewState
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: row.movement.type.iconName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(row.movement.type.tintColor)
                    .frame(width: 82, height: 82)
                    .background(row.movement.type.softColor, in: RoundedRectangle(cornerRadius: 8))

                if row.isArchived {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color(.systemOrange), in: Circle())
                        .offset(x: 6, y: 6)
                }
            }

            VStack(spacing: 7) {
                Text(row.movement.type.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(row.movement.type.tintColor)

                Text(row.amountText)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(row.movement.amount < Decimal.zero ? Color(.systemRed) : Color(.systemGreen))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                HStack(spacing: 8) {
                    Text(row.movement.status.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(row.movement.status.tintColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(row.movement.status.tintColor.opacity(0.12), in: Capsule())

                    Text(MovementFormatters.fullDateTime(row.movement.transactionDate))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }

            if isLoading {
                Text(row.movement.reference)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(row.movement.type.tintColor.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct DetailInfoRow: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 32, height: 32)
                .background(Color(.systemBlue).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
