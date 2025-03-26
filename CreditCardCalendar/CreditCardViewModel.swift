//
//  CreditCardViewModel.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import Foundation
import Combine
import UserNotifications
import WidgetKit

class CreditCardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var creditCards: [CreditCard] = []
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    // MARK: - Dependencies
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - App Group Configuration
    private let appGroup = "group.com.zaidgarcia.CreditCardCalendar"
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadCards()
        requestNotificationPermission()
    }
    
    // MARK: - Public Methods
    
    func addCard(name: String, cutDay: Int, paymentDays: Int, colorCode: String? = nil) {
        guard !name.isEmpty else {
            showError("El nombre de la tarjeta no puede estar vacío")
            return
        }
        
        guard (1...31).contains(cutDay) else {
            showError("El día de corte debe estar entre 1 y 31")
            return
        }
        
        guard (1...30).contains(paymentDays) else {
            showError("Los días de pago deben estar entre 1 y 30")
            return
        }
        
        let color = colorCode ?? ColorPalette.randomColor()
        let newCard = CreditCard(name: name, cutDay: cutDay, paymentDays: paymentDays, colorCode: color)
        creditCards.append(newCard)
        scheduleNotifications(for: newCard)
        saveCards()
        updateWidget()
    }
    
    func deleteCard(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let card = creditCards[index]
            notificationManager.cancelScheduledNotifications(for: card)
        }
        creditCards.remove(atOffsets: indexSet)
        saveCards()
        updateWidget()
    }
    
    func deleteCard(_ card: CreditCard) {
        if let index = creditCards.firstIndex(where: { $0.id == card.id }) {
            notificationManager.cancelScheduledNotifications(for: card)
            creditCards.remove(at: index)
            saveCards()
            updateWidget()
        }
    }
    
    func updateCard(_ card: CreditCard,
                   newName: String? = nil,
                   newCutDay: Int? = nil,
                   newPaymentDays: Int? = nil,
                   newColorCode: String? = nil) {
        guard let index = creditCards.firstIndex(where: { $0.id == card.id }) else { return }
        
        var updatedCard = creditCards[index]
        
        if let newName = newName, !newName.isEmpty {
            updatedCard.name = newName
        }
        
        if let newCutDay = newCutDay, (1...31).contains(newCutDay) {
            updatedCard.cutDay = newCutDay
        }
        
        if let newPaymentDays = newPaymentDays, (1...30).contains(newPaymentDays) {
            updatedCard.paymentDays = newPaymentDays
        }
        
        if let newColorCode = newColorCode, !newColorCode.isEmpty {
            updatedCard.colorCode = newColorCode
        }
        
        // Actualizar notificaciones
        notificationManager.cancelScheduledNotifications(for: card)
        creditCards[index] = updatedCard
        scheduleNotifications(for: updatedCard)
        saveCards()
        updateWidget()
    }
    
    func rescheduleAllNotifications() {
        notificationManager.rescheduleAllNotifications(for: creditCards)
    }
    
    // MARK: - Widget Management
    
    private func updateWidget() {
        // Actualizar los widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        // Guardar datos simplificados para el widget
        saveWidgetData()
    }
    
    private func saveWidgetData() {
        let widgetCards = creditCards.map { card in
            [
                "id": card.id.uuidString,
                "name": card.name,
                "dueDate": card.paymentDueDate().timeIntervalSince1970,
                "color": card.colorCode,
                "status": card.paymentDueStatus.rawValue
            ]
        }
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            sharedDefaults.set(widgetCards, forKey: "widgetCreditCards")
        }
    }
    
    // MARK: - Notification Management
    
    private func scheduleNotifications(for card: CreditCard) {
        notificationManager.schedulePaymentReminder(for: card)
        notificationManager.scheduleCutDateReminder(for: card)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        notificationManager.$authorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                if authorized {
                    self?.rescheduleAllNotifications()
                }
            }
            .store(in: &cancellables)
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestAuthorization { [weak self] granted in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let self = self else { return }
                if !self.notificationManager.authorized {
                    self.showError("Las notificaciones están desactivadas. Actívalas en Ajustes para recibir recordatorios")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Persistence
    
    private func saveCards() {
        do {
            let data = try JSONEncoder().encode(creditCards)
            // Guardar en UserDefaults estándar
            UserDefaults.standard.set(data, forKey: "savedCreditCards")
            
            // Guardar en App Group para compartir con widgets
            if let sharedDefaults = UserDefaults(suiteName: appGroup) {
                sharedDefaults.set(data, forKey: "sharedCreditCards")
            }
        } catch {
            showError("Error al guardar las tarjetas: \(error.localizedDescription)")
        }
    }
    
    private func loadCards() {
        // Primero intenta cargar desde App Group (para consistencia con widget)
        if let sharedData = UserDefaults(suiteName: appGroup)?.data(forKey: "sharedCreditCards") {
            decodeAndSetCards(from: sharedData)
            return
        }
        
        // Fallback a UserDefaults estándar
        if let standardData = UserDefaults.standard.data(forKey: "savedCreditCards") {
            decodeAndSetCards(from: standardData)
        }
    }
    
    private func decodeAndSetCards(from data: Data) {
        do {
            creditCards = try JSONDecoder().decode([CreditCard].self, from: data)
            print("✅ Tarjetas cargadas: \(creditCards.count)")
        } catch {
            showError("Error al cargar las tarjetas: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Extensions
extension CreditCardViewModel {
    func cardsDueThisWeek() -> [CreditCard] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: today) else { return [] }
        
        return creditCards.filter { card in
            let paymentDate = card.paymentDueDate()
            return paymentDate >= today && paymentDate <= weekEnd
        }
    }
    
    func upcomingCutDates() -> [(card: CreditCard, date: Date)] {
        creditCards.map { ($0, $0.nextCutDate()) }
            .sorted { $0.date < $1.date }
    }
    
    func cardsFiltered(by status: CreditCard.PaymentStatus) -> [CreditCard] {
        creditCards.filter { $0.paymentDueStatus == status }
    }
    
    func cardsForWidget() -> [CreditCard] {
        // Devuelve las tarjetas ordenadas por fecha de vencimiento
        return creditCards.sorted { $0.paymentDueDate() < $1.paymentDueDate() }
    }
}


