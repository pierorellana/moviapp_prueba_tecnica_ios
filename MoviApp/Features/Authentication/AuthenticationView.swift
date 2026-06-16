import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var isPulsing = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    securityPanel
                    primaryAction
                    securityHighlights
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.vertical, 34)
                .frame(minHeight: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .task {
            await viewModel.authenticateOnLaunch()
        }
    }

    private var background: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(.systemBlue).opacity(0.18),
                    Color(.systemGreen).opacity(0.12),
                    Color(.systemGroupedBackground).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Acceso seguro", systemImage: "lock.shield.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(.systemBlue))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())

            VStack(alignment: .leading, spacing: 6) {
                Text("Gestión")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Confirma tu identidad para consultar tus movimientos de forma protegida.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var securityPanel: some View {
        VStack(spacing: 22) {
            biometricIndicator

            VStack(spacing: 10) {
                statusBadge

                Text(statusTitle)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                if let message = statusMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if showsProgress {
                ProgressView()
                    .controlSize(.regular)
                    .tint(Color(.systemBlue))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        }
    }

    private var biometricIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(showsProgress ? 0.16 : 0.1))
                .frame(width: 156, height: 156)
                .scaleEffect(showsProgress && isPulsing ? 1.08 : 0.98)
                .opacity(showsProgress ? 1 : 0.75)

            Circle()
                .stroke(statusColor.opacity(0.18), lineWidth: 14)
                .frame(width: 128, height: 128)

            Circle()
                .trim(from: 0.08, to: showsProgress ? 0.82 : 1)
                .stroke(
                    AngularGradient(
                        colors: [statusColor.opacity(0.15), statusColor, Color(.systemGreen)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(showsProgress && isPulsing ? 360 : 0))

            Image(systemName: iconName)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 88, height: 88)
                .background(Color(.systemBackground).opacity(0.92), in: Circle())
        }
        .animation(.easeInOut(duration: 0.25), value: showsProgress)
        .animation(
            showsProgress ? .linear(duration: 1.4).repeatForever(autoreverses: false) : .easeOut(duration: 0.25),
            value: isPulsing
        )
        .accessibilityHidden(true)
    }

    private var statusBadge: some View {
        Label(statusBadgeTitle, systemImage: statusBadgeIcon)
            .font(.caption.weight(.bold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(statusColor.opacity(0.12), in: Capsule())
    }

    private var primaryAction: some View {
        Button {
            Task { await viewModel.authenticate() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: buttonIconName)
                Text(buttonTitle)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(showsProgress)
        .opacity(showsProgress ? 0.78 : 1)
        .accessibilityLabel(buttonTitle)
    }

    private var securityHighlights: some View {
        VStack(spacing: 10) {
            SecurityHighlightRow(
                iconName: "eye.slash.fill",
                title: "Datos protegidos",
                message: "La consulta se desbloquea solo después de confirmar tu identidad."
            )
        }
    }

    private var iconName: String {
        switch viewModel.state {
        case .authenticated:
            "checkmark.shield.fill"
        case .unavailable, .failed:
            "exclamationmark.triangle.fill"
        case .prompting(.faceID):
            "faceid"
        case .prompting(.touchID):
            "touchid"
        default:
            "lock.shield.fill"
        }
    }

    private var showsProgress: Bool {
        switch viewModel.state {
        case .checking, .prompting:
            true
        default:
            false
        }
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle, .checking:
            "Validando biometría"
        case .prompting(let kind):
            "Usa \(kind.title)"
        case .authenticated:
            "Acceso autorizado"
        case .unavailable(let error), .failed(let error):
            error.localizedDescription
        }
    }

    private var statusMessage: String? {
        switch viewModel.state {
        case .idle, .checking, .prompting:
            "La pantalla de movimientos permanece bloqueada hasta confirmar tu identidad."
        case .unavailable(.notEnrolled):
            "Configura Face ID o Touch ID en Ajustes y vuelve a intentar."
        case .unavailable(.notAvailable):
            "Prueba en un dispositivo con biometría o en un simulador con Face ID enrolado."
        case .unavailable(.lockedOut), .failed(.lockedOut):
            "Espera unos minutos o desbloquea la biometría desde el sistema."
        case .failed(.userCancelled):
            "Puedes reintentar cuando estés listo."
        case .failed, .unavailable:
            "Revisa que el dispositivo permita usar biometría para esta app."
        case .authenticated:
            nil
        }
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .idle, .checking, .prompting:
            "Autenticando"
        default:
            "Intentar nuevamente"
        }
    }

    private var buttonIconName: String {
        switch viewModel.state {
        case .idle, .checking, .prompting:
            "lock.fill"
        case .authenticated:
            "checkmark.circle.fill"
        default:
            "arrow.clockwise"
        }
    }

    private var buttonBackground: Color {
        showsProgress ? Color(.systemGray) : statusColor
    }

    private var statusBadgeTitle: String {
        switch viewModel.state {
        case .authenticated:
            "Verificado"
        case .unavailable, .failed:
            "Requiere atención"
        default:
            "Protección activa"
        }
    }

    private var statusBadgeIcon: String {
        switch viewModel.state {
        case .authenticated:
            "checkmark.circle.fill"
        case .unavailable, .failed:
            "exclamationmark.circle.fill"
        default:
            "shield.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .authenticated:
            Color(.systemGreen)
        case .unavailable, .failed:
            Color(.systemOrange)
        default:
            Color(.systemBlue)
        }
    }
}

private struct SecurityHighlightRow: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 32, height: 32)
                .background(Color(.systemBlue).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
    }
}
