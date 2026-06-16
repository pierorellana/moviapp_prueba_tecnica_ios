import SwiftUI

struct MovementsView: View {
    @ObservedObject var viewModel: MovementsViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                MovementsHeaderView(
                    selectedRange: viewModel.selectedRange,
                    onRangeSelected: { range in
                        Task { await viewModel.setDateRange(range) }
                    }
                )

                MovementsSummaryView(
                    movementCount: viewModel.visibleMovementCount,
                    netAmountText: viewModel.visibleNetAmountText,
                    creditCount: viewModel.visibleCreditCount,
                    debitCount: viewModel.visibleDebitCount
                )

                MovementSearchBar(
                    text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.setSearchText($0) }
                    )
                )

                ArchiveFilterTabs(
                    selection: Binding(
                        get: { viewModel.selectedFilter },
                        set: { viewModel.setFilter($0) }
                    )
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(headerBackground)

            content
        }
        .background(screenBackground)
        .task {
            await viewModel.loadInitialIfNeeded()
        }
        .overlay(alignment: .bottom) {
            actionToast
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: viewModel.actionMessage)
        .sheet(isPresented: detailPresentationBinding) {
            MovementDetailSheetView(
                state: viewModel.detailState,
                onDismiss: { viewModel.dismissMovementDetail() },
                onRetry: { Task { await viewModel.retrySelectedMovementDetail() } },
                onToggleArchive: { Task { await viewModel.toggleSelectedDetailArchive() } }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var screenBackground: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [
                    Color(.systemBlue).opacity(0.12),
                    Color(.systemGreen).opacity(0.08),
                    Color(.systemGroupedBackground).opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var headerBackground: some View {
        Rectangle()
            .fill(.thinMaterial)
            .background(Color(.systemGroupedBackground).opacity(0.8))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text("Cargando movimientos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            movementList

        case .empty:
            ScrollView {
                AppStateView(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Sin movimientos",
                    message: "No encontramos movimientos para el filtro actual.",
                    actionTitle: "Actualizar",
                    action: { Task { await viewModel.refresh() } }
                )
            }
            .refreshable {
                await viewModel.refresh()
            }

        case .error(let message):
            ScrollView {
                AppStateView(
                    systemImage: "wifi.exclamationmark",
                    title: "No se pudo cargar",
                    message: message,
                    actionTitle: "Reintentar",
                    action: { Task { await viewModel.refresh() } }
                )
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var movementList: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        Button {
                            Task { await viewModel.selectMovement(row) }
                        } label: {
                            MovementCardView(row: row)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                Task { await viewModel.toggleArchive(for: row) }
                            } label: {
                                Label(row.isArchived ? "Desarchivar" : "Archivar", systemImage: row.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                            .tint(row.isArchived ? Color(.systemGreen) : Color(.systemOrange))
                        }
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(currentItemID: row.id) }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text(section.title)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                        .padding(.top, 8)
                        .padding(.leading, 2)
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: viewModel.sections)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var actionToast: some View {
        if let message = viewModel.actionMessage {
            AppToastView(message: message) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                    viewModel.dismissActionMessage()
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            )
        }
    }

    private var detailPresentationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isDetailPresented },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissMovementDetail()
                }
            }
        )
    }
}
