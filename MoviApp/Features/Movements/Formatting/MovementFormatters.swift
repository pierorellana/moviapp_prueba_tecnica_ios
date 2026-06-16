import Foundation

enum MovementFormatters {
    static func amount(_ value: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    static func timeOrShortDate(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_EC")
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    static func fullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
