import Foundation

enum MovementDateGroup: Int, CaseIterable, Identifiable {
    case today
    case thisWeek
    case last7Days
    case last15Days
    case last30Days
    case previousMonth
    case twoMonthsAgo
    case threeMonthsAgo

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today:
            "Hoy"
        case .thisWeek:
            "Esta semana"
        case .last7Days:
            "Últimos 7 días"
        case .last15Days:
            "Últimos 15 días"
        case .last30Days:
            "Últimos 30 días"
        case .previousMonth:
            "Mes anterior"
        case .twoMonthsAgo:
            "Hace 2 meses"
        case .threeMonthsAgo:
            "Hace 3 meses"
        }
    }
}

struct MovementDateGrouper {
    var calendar: Calendar = .current

    func group(for date: Date, referenceDate: Date = Date()) -> MovementDateGroup? {
        let dayStart = calendar.startOfDay(for: date)
        let referenceStart = calendar.startOfDay(for: referenceDate)
        let days = calendar.dateComponents([.day], from: dayStart, to: referenceStart).day ?? Int.max

        guard days >= 0 else {
            return .today
        }

        if days == 0 {
            return .today
        }

        if calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear),
           calendar.isDate(date, equalTo: referenceDate, toGranularity: .yearForWeekOfYear) {
            return .thisWeek
        }

        if days <= 7 {
            return .last7Days
        }

        if days <= 15 {
            return .last15Days
        }

        if days <= 30 {
            return .last30Days
        }

        let monthDistance = calendar.dateComponents(
            [.month],
            from: monthStart(for: date),
            to: monthStart(for: referenceDate)
        ).month

        switch monthDistance {
        case 1:
            return .previousMonth
        case 2:
            return .twoMonthsAgo
        case 3:
            return .threeMonthsAgo
        default:
            return nil
        }
    }

    private func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}
