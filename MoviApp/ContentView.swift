//
//  ContentView.swift
//  MoviApp
//
//  Created by Jorge on 16/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authenticationViewModel: AuthenticationViewModel
    @StateObject private var movementsViewModel: MovementsViewModel

    @MainActor
    init() {
        self.init(container: .live())
    }

    @MainActor
    init(container: AppDependencyContainer) {
        _authenticationViewModel = StateObject(
            wrappedValue: AuthenticationViewModel(service: container.biometricService)
        )
        _movementsViewModel = StateObject(
            wrappedValue: MovementsViewModel(
                repository: container.movementRepository,
                archivedStore: container.archivedMovementStore,
                config: container.config,
                dateGrouper: MovementDateGrouper(),
                calendar: .current
            )
        )
    }

    var body: some View {
        Group {
            switch authenticationViewModel.state {
            case .authenticated:
                MovementsView(viewModel: movementsViewModel)
            default:
                AuthenticationView(viewModel: authenticationViewModel)
            }
        }
    }
}

#Preview {
    ContentView(container: .preview)
}
