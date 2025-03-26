//
//  CreditCard.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import Foundation

struct CreditCard: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Properties
    let id: UUID
    var name: String
    var cutDay: Int  // Día del mes (1-31)
    var paymentDays: Int  // Días para pagar después del corte
    var lastUpdated: Date
    var colorCode: String  // Para UI
    
    // MARK: - Initializers
    init(id: UUID = UUID(),
         name: String,
         cutDay: Int,
         paymentDays: Int,
         lastUpdated: Date = Date(),
         colorCode: String = ColorPalette.randomColor()) {
        self.id = id
        self.name = name
        self.cutDay = cutDay
        self.paymentDays = paymentDays
        self.lastUpdated = lastUpdated
        self.colorCode = colorCode
    }
    
    // MARK: - Date Calculations
    func nextCutDate(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = cutDay
        
        guard var cutDate = calendar.date(from: components) else {
            return date  // Fallback (no debería ocurrir)
        }
        
        // Si la fecha de corte ya pasó este mes, usar el próximo mes
        if cutDate < date {
            cutDate = calendar.date(byAdding: .month, value: 1, to: cutDate) ?? date
        }
        
        return cutDate
    }
    
    func paymentDueDate() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: paymentDays, to: nextCutDate()) ?? Date()
    }
    
    func daysUntilPayment() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: paymentDueDate())
        return components.day ?? 0
    }
    
    // MARK: - Helper Properties
    var paymentDueStatus: PaymentStatus {
        let daysLeft = daysUntilPayment()
        
        switch daysLeft {
        case ...0:
            return .overdue
        case 1...3:
            return .urgent
        case 4...7:
            return .upcoming
        default:
            return .normal
        }
    }
    
    var nextCutFormatted: String {
        nextCutDate().formatted(.dateTime.day().month(.wide))
    }
    
    var paymentDueFormatted: String {
        paymentDueDate().formatted(.dateTime.day().month(.wide).year())
    }
    
    // MARK: - Enums
    enum PaymentStatus: String, Codable {
        case normal = "Al día"
        case upcoming = "Próximo"
        case urgent = "Urgente"
        case overdue = "Vencido"
        
        var color: String {
            switch self {
            case .normal: return ColorPalette.green
            case .upcoming: return ColorPalette.yellow
            case .urgent: return ColorPalette.orange
            case .overdue: return ColorPalette.red
            }
        }
    }
}



// MARK: - Sample Data (para previews)
extension CreditCard {
    static let sampleData: [CreditCard] = [
        CreditCard(name: "Visa Platinum", cutDay: 15, paymentDays: 20, colorCode: ColorPalette.blue),
        CreditCard(name: "Mastercard Gold", cutDay: 5, paymentDays: 25, colorCode: ColorPalette.yellow),
        CreditCard(name: "Amex Preferred", cutDay: 22, paymentDays: 15, colorCode: ColorPalette.green)
    ]
    
    static func sample() -> CreditCard {
        sampleData[0]
    }
}

