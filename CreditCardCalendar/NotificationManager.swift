//
//  NotificationManager.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    @Published var authorized: Bool = false
    @Published var showingPermissionAlert: Bool = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func checkAuthorizationStatus() {
            center.getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    let newStatus = settings.authorizationStatus == .authorized
                    if self?.authorized != newStatus {
                        self?.authorized = newStatus
                    }
                }
            }
        }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.authorized = granted
                    self?.checkAuthorizationStatus() // Verificación adicional
                    
                    if let error = error {
                        print("🔔 Error en permisos: \(error.localizedDescription)")
                    }
                    completion?(granted)
                }
            }
        }
    
    // MARK: - Notification Scheduling
    func schedulePaymentReminder(for card: CreditCard, daysBefore: Int = 3) {
        guard authorized else {
            print("⚠️ Not authorized to schedule notifications")
            return
        }
        
        let paymentDate = card.paymentDueDate()
        let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: paymentDate)!
        
        let content = UNMutableNotificationContent()
        content.title = "💰 Recordatorio de Pago"
        content.body = "Tu tarjeta \(card.name) vence el \(paymentDate.formatted(.dateTime.day().month().year()))"
        content.sound = .default
        content.userInfo = ["cardID": card.id.uuidString]
        
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                             from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "payment-reminder-\(card.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("🔔 Error scheduling payment reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled payment reminder for \(card.name) on \(reminderDate.formatted())")
            }
        }
    }
    
    func scheduleCutDateReminder(for card: CreditCard) {
        guard authorized else { return }
        
        let cutDate = card.nextCutDate()
        
        let content = UNMutableNotificationContent()
        content.title = "📅 Corte de Tarjeta"
        content.body = "Hoy es el día de corte para tu tarjeta \(card.name)"
        content.sound = .defaultCritical
        content.userInfo = ["cardID": card.id.uuidString]
        
        var triggerComponents = Calendar.current.dateComponents([.year, .month, .day],
                                                             from: cutDate)
        triggerComponents.hour = 9 // Notificar a las 9 AM
        triggerComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "cut-date-\(card.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("🔔 Error scheduling cut date reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func cancelScheduledNotifications(for card: CreditCard) {
        center.removePendingNotificationRequests(withIdentifiers: [
            "payment-reminder-\(card.id.uuidString)",
            "cut-date-\(card.id.uuidString)"
        ])
        print("🗑️ Cancelled notifications for card: \(card.name)")
    }
    
    func cancelAllScheduledNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🧹 Cancelled all scheduled notifications")
    }
    
    // MARK: - Helper Methods
    func rescheduleAllNotifications(for cards: [CreditCard]) {
        cancelAllScheduledNotifications()
        cards.forEach { card in
            schedulePaymentReminder(for: card)
            scheduleCutDateReminder(for: card)
        }
    }
}

// MARK: - UI Integration
extension NotificationManager {
    func presentNotificationSettingsAlert() -> Alert {
        Alert(
            title: Text("Notificaciones Desactivadas"),
            message: Text("Por favor activa las notificaciones en Ajustes para recibir recordatorios"),
            primaryButton: .default(Text("Abrir Ajustes")) {
                self.openAppSettings()
            },
            secondaryButton: .cancel()
        )
    }
    
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

