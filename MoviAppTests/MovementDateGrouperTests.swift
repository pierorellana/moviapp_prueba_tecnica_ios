import XCTest
@testable import MoviApp

final class MovementDateGrouperTests: XCTestCase {
    func testGroupsDatesByRequiredBuckets() {
        let calendar = Calendar.gregorianUTC
        let reference = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 12))!
        let grouper = MovementDateGrouper(calendar: calendar)

        XCTAssertEqual(grouper.group(for: date(daysAgo: 0, reference: reference), referenceDate: reference), .today)
        XCTAssertEqual(grouper.group(for: date(daysAgo: 1, reference: reference), referenceDate: reference), .thisWeek)
        XCTAssertEqual(grouper.group(for: date(daysAgo: 7, reference: reference), referenceDate: reference), .last7Days)
        XCTAssertEqual(grouper.group(for: date(daysAgo: 12, reference: reference), referenceDate: reference), .last15Days)
        XCTAssertEqual(grouper.group(for: date(daysAgo: 22, reference: reference), referenceDate: reference), .last30Days)

        let previousMonth = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 12))!
        let twoMonthsAgo = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 12))!
        let threeMonthsAgo = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!

        XCTAssertEqual(grouper.group(for: previousMonth, referenceDate: reference), .previousMonth)
        XCTAssertEqual(grouper.group(for: twoMonthsAgo, referenceDate: reference), .twoMonthsAgo)
        XCTAssertEqual(grouper.group(for: threeMonthsAgo, referenceDate: reference), .threeMonthsAgo)
    }

    private func date(daysAgo: Int, reference: Date) -> Date {
        Calendar.gregorianUTC.date(byAdding: .day, value: -daysAgo, to: reference)!
    }
}
