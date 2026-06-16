import Foundation

protocol RequestInterceptor {
    func adapt(_ request: URLRequest) -> URLRequest
}

struct DefaultRequestInterceptor: RequestInterceptor {
    func adapt(_ request: URLRequest) -> URLRequest {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS", forHTTPHeaderField: "X-Client-Platform")
        request.timeoutInterval = 25
        return request
    }
}
