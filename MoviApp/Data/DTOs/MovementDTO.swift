import Foundation

struct MovementDTO: Decodable {
    let id: UUID
    let accountId: UUID?
    let type: String
    let personName: String
    let description: String
    let reference: String
    let amount: Decimal
    let currency: String
    let status: String
    let transactionDate: Date
    let createdAt: Date?
    let category: String
    let channel: String

    func toDomain() -> Movement {
        Movement(
            id: id,
            accountId: accountId,
            type: MovementType(rawValue: type) ?? .transfer,
            personName: personName,
            description: description,
            reference: reference,
            amount: amount,
            currency: currency,
            status: MovementStatus(rawValue: status) ?? .unknown(status),
            transactionDate: transactionDate,
            createdAt: createdAt,
            category: category,
            channel: channel
        )
    }
}
