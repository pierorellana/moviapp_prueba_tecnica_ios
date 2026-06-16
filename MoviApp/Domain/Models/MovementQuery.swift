import Foundation

struct MovementQuery: Equatable {
    var page: Int
    var pageSize: Int
    var fromDate: Date?
    var toDate: Date?
    var search: String?
    var sort: String = "date_desc"
}
