//
//  ContentView.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CreditCardViewModel()
    @State private var showingAddCard = false
    @State private var showingNotificationsAlert = false
    @State private var selectedCard: CreditCard?
    @State private var showingDetail = false
    
    // Para búsqueda y filtrado
    @State private var searchText = ""
    @State private var filterOption: PaymentStatusFilter = .all
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.creditCards.isEmpty {
                    emptyStateView
                } else {
                    cardsListView
                }
            }
            .navigationTitle("Mis Tarjetas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addCardButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    filterMenu
                }
            }
            .searchable(text: $searchText, prompt: "Buscar tarjetas")
            .sheet(isPresented: $showingAddCard) {
                AddCardView(viewModel: viewModel)
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card, viewModel: viewModel)
            }
            .alert("Notificaciones", isPresented: $viewModel.showAlert) {
                Button("Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .onAppear {
                checkNotificationAuthorization()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No hay tarjetas registradas")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button(action: { showingAddCard = true }) {
                Label("Añadir Tarjeta", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardsListView: some View {
        List {
            ForEach(filteredCards) { card in
                CardRowView(card: card)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteCard(card)
                            }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                        Button {
                            selectedCard = card
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .onTapGesture {
                        selectedCard = card
                    }
            }
        }
        .refreshable {
            viewModel.rescheduleAllNotifications()
        }
    }
    
    private var addCardButton: some View {
        Button(action: { showingAddCard = true }) {
            Image(systemName: "plus")
                .imageScale(.large)
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Picker("Filtrar por estado", selection: $filterOption) {
                ForEach(PaymentStatusFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredCards: [CreditCard] {
        var cards = viewModel.creditCards
        
        // Aplicar filtro de búsqueda
        if !searchText.isEmpty {
            cards = cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Aplicar filtro por estado
        switch filterOption {
        case .all:
            return cards.sorted { $0.paymentDueDate() < $1.paymentDueDate() }
        case .normal:
            return cards.filter { $0.paymentDueStatus == .normal }
        case .upcoming:
            return cards.filter { $0.paymentDueStatus == .upcoming }
        case .urgent:
            return cards.filter { $0.paymentDueStatus == .urgent }
        case .overdue:
            return cards.filter { $0.paymentDueStatus == .overdue }
        }
    }
    
    // MARK: - Methods
    
    private func deleteCard(_ card: CreditCard) {
        if let index = viewModel.creditCards.firstIndex(where: { $0.id == card.id }) {
            viewModel.deleteCard(at: IndexSet([index]))
        }
    }
    
    private func checkNotificationAuthorization() {
        if !NotificationManager.shared.authorized {
            showingNotificationsAlert = true
        }
    }
    
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Supporting Views

struct CardRowView: View {
    let card: CreditCard
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicador de color
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(card.colorCode))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Indicador de estado
                    Circle()
                        .fill(Color(card.paymentDueStatus.color))
                        .frame(width: 12, height: 12)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Corte")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.nextCutFormatted)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Vence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.paymentDueFormatted)
                            .font(.subheadline)
                            .foregroundColor(card.paymentDueStatus == .overdue ? .red : .primary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Enums

enum PaymentStatusFilter: String, CaseIterable {
    case all = "Todas"
    case normal = "Al día"
    case upcoming = "Próximas"
    case urgent = "Urgentes"
    case overdue = "Vencidas"
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CreditCardViewModel())
        
        ContentView()
            .environmentObject({
                let vm = CreditCardViewModel()
                vm.creditCards = CreditCard.sampleData
                return vm
            }())
    }
}
