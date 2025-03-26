//
//  CardDetailView.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import SwiftUI

struct CardDetailView: View {
    @ObservedObject var viewModel: CreditCardViewModel
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedCutDay: Int
    @State private var editedPaymentDays: Int
    @State private var selectedColor: String
    
    let card: CreditCard
    
    init(card: CreditCard, viewModel: CreditCardViewModel) {
        self.card = card
        self.viewModel = viewModel
        _editedName = State(initialValue: card.name)
        _editedCutDay = State(initialValue: card.cutDay)
        _editedPaymentDays = State(initialValue: card.paymentDays)
        _selectedColor = State(initialValue: card.colorCode)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Información de la Tarjeta")) {
                if isEditing {
                    TextField("Nombre", text: $editedName)
                    
                    Picker("Día de Corte", selection: $editedCutDay) {
                        ForEach(1..<32, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    
                    Picker("Días para Pago", selection: $editedPaymentDays) {
                        ForEach(1..<31, id: \.self) { days in
                            Text("\(days) días").tag(days)
                        }
                    }
                    
                    ColorPickerSection(selectedColor: $selectedColor)
                } else {
                    HStack {
                        Text("Nombre")
                        Spacer()
                        Text(card.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Día de Corte")
                        Spacer()
                        Text("\(card.cutDay)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Días para Pago")
                        Spacer()
                        Text("\(card.paymentDays) días")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(Color(card.colorCode))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            Section(header: Text("Próximas Fechas")) {
                HStack {
                    Text("Próximo Corte")
                    Spacer()
                    Text(card.nextCutFormatted)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Fecha Límite")
                    Spacer()
                    Text(card.paymentDueFormatted)
                        .foregroundColor(card.paymentDueStatus == .overdue ? .red : .secondary)
                }
                
                HStack {
                    Text("Estado")
                    Spacer()
                    Text(card.paymentDueStatus.rawValue)
                        .foregroundColor(Color(card.paymentDueStatus.color))
                }
            }
            
            if !isEditing {
                Section {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Editar Tarjeta")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button(role: .destructive) {
                        viewModel.deleteCard(card)
                    } label: {
                        Text("Eliminar Tarjeta")
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Section {
                    Button(action: saveChanges) {
                        Text("Guardar Cambios")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(editedName.isEmpty)
                    
                    Button(role: .cancel) {
                        isEditing = false
                        resetForm()
                    } label: {
                        Text("Cancelar")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Editar Tarjeta" : card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        saveChanges()
                    }
                    .disabled(editedName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        viewModel.updateCard(
            card,
            newName: editedName,
            newCutDay: editedCutDay,
            newPaymentDays: editedPaymentDays,
            newColorCode: selectedColor
        )
        isEditing = false
    }
    
    private func resetForm() {
        editedName = card.name
        editedCutDay = card.cutDay
        editedPaymentDays = card.paymentDays
        selectedColor = card.colorCode
    }
}



struct ColorPickerSection: View {
    @Binding var selectedColor: String
    let colors = ColorPalette.allColors()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Color")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors, id: \.self) { color in
                        colorCircleView(color: color)
                    }
                }
                .padding(.vertical, 5)
                .frame(height: 40) // Altura fija para asegurar visibilidad
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6)) // Fondo visible para debug
            )
        }
    }
    
    // Función separada para crear cada círculo de color
    private func colorCircleView(color: String) -> some View {
        let isSelected = selectedColor == color
        
        return Circle()
            .fill(Color(hex: color)) // Asegúrate de tener la extensión Color(hex:)
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                selectedColor = color
                print("Color seleccionado: \(color)") // Debug
            }
            .padding(2)
    }
}

struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CardDetailView(
                card: CreditCard(
                    name: "Visa Platinum",
                    cutDay: 15,
                    paymentDays: 20,
                    colorCode: ColorPalette.blue
                ),
                viewModel: CreditCardViewModel()
            )
        }
    }
}
