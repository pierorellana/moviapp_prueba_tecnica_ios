import Foundation

struct AppConfig {
    let baseURL: URL
    let defaultPageSize: Int

    nonisolated static let live = AppConfig(
        baseURL: URL(string: "https://w3qz8bsw-7217.use.devtunnels.ms")!,
        defaultPageSize: 30
    )
}
