//
//  CreditCardWidgets.swift
//  CreditCardWidgets
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import WidgetKit
import SwiftUI

// 1. Define la estructura del modelo para el widget
struct WidgetCreditCard: Identifiable {
    let id: String
    let name: String
    let paymentDueDate: Date
    let colorCode: String
    let status: String
    
    // Formateador para la fecha
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: paymentDueDate)
    }
}

// 2. Proveedor de datos
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        CardEntry(date: Date(), cards: [
            WidgetCreditCard(
                id: UUID().uuidString,
                name: "Tarjeta Ejemplo",
                paymentDueDate: Date().addingTimeInterval(86400 * 3), // 3 días en el futuro
                colorCode: "#2196F3",
                status: "Próximo"
            )
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
        let cards = loadCards()
        let entry = CardEntry(date: Date(), cards: cards)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
        let cards = loadCards()
        let entry = CardEntry(date: Date(), cards: cards)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))) // Actualizar cada hora
        completion(timeline)
    }
    
    private func loadCards() -> [WidgetCreditCard] {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.zaidgarcia.CreditCardCalendar"),
              let data = sharedDefaults.data(forKey: "sharedCreditCards") else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let creditCards = try decoder.decode([CreditCard].self, from: data)
            return creditCards.map { card in
                WidgetCreditCard(
                    id: card.id.uuidString,
                    name: card.name,
                    paymentDueDate: card.paymentDueDate(),
                    colorCode: card.colorCode,
                    status: card.paymentDueStatus.rawValue
                )
            }
        } catch {
            print("Error decoding cards: \(error)")
            return []
        }
    }
}

// 3. Entrada de la línea de tiempo
struct CardEntry: TimelineEntry {
    let date: Date
    let cards: [WidgetCreditCard]
}

// 4. Vista principal del widget
struct CreditCardWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallCardView(cards: entry.cards)
            case .systemMedium:
                MediumCardView(cards: entry.cards)
            default:
                MediumCardView(cards: entry.cards)
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground) // Fondo adaptable al modo claro/oscuro
        }
    }
}

struct SmallCardView: View {
    let cards: [WidgetCreditCard]
    
    var body: some View {
        VStack(alignment: .leading) {
            if let nextCard = cards.sorted(by: { $0.paymentDueDate < $1.paymentDueDate }).first {
                SingleCardView(card: nextCard)
            } else {
                Text("No hay tarjetas")
                    .font(.caption)
            }
        }
        .padding()
        .background() // Fondo transparente para heredar el containerBackground
    }
}

struct MediumCardView: View {
    let cards: [WidgetCreditCard]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(cards.sorted(by: { $0.paymentDueDate < $1.paymentDueDate }).prefix(3)) { card in
                SingleCardView(card: card)
                if card.id != cards.last?.id {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .padding()
        .background() // Fondo transparente
    }
}

struct SingleCardView: View {
    let card: WidgetCreditCard
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: card.colorCode))
                .frame(width: 4, height: 20)
            
            VStack(alignment: .leading) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary) // Usa colores dinámicos
                Text("Vence: \(card.formattedDueDate)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: card.status)
        }
    }
}


struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case "Vencido": return .red
        case "Urgente": return .orange
        case "Próximo": return .yellow
        default: return .green
        }
    }
}


// 7. Configuración del widget
@main
struct CreditCardWidgets: Widget {
    let kind: String = "CreditCardWidgets"  // <- Este es el ID interno (no visible al usuario)
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            CreditCardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Mis TDC")  // ⭐️ Cambia este texto
        .description("Muestra tus próximos vencimientos")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
