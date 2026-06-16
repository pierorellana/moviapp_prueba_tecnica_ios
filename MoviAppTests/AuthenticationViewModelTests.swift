import XCTest
@testable import MoviApp

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    func testBiometricAuthenticationSuccess() async {
        let service = MockBiometricService()
        let viewModel = AuthenticationViewModel(service: service)

        await viewModel.authenticate()

        XCTAssertEqual(viewModel.state, .authenticated)
    }

    func testBiometricAuthenticationError() async {
        let service = MockBiometricService(
            availabilityResult: .available(.faceID),
            authenticationError: .userCancelled
        )
        let viewModel = AuthenticationViewModel(service: service)

        await viewModel.authenticate()

        XCTAssertEqual(viewModel.state, .failed(.userCancelled))
    }

    func testBiometricNotConfiguredState() async {
        let service = MockBiometricService(availabilityResult: .unavailable(.notEnrolled))
        let viewModel = AuthenticationViewModel(service: service)

        await viewModel.authenticate()

        XCTAssertEqual(viewModel.state, .unavailable(.notEnrolled))
    }
}
