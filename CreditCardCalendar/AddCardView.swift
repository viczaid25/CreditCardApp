//
//  AddCardView.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
import SwiftUI

struct AddCardView: View {
    @ObservedObject var viewModel: CreditCardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var cutDay = 1
    @State private var paymentDays = 20
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la Tarjeta")) {
                    TextField("Nombre de la tarjeta", text: $name)
                    
                    Picker("Día de corte", selection: $cutDay) {
                        ForEach(1..<32) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    
                    Picker("Días para pagar", selection: $paymentDays) {
                        ForEach(1..<31) { days in
                            Text("\(days) días").tag(days)
                        }
                    }
                }
                
                Section {
                    Button("Guardar") {
                        viewModel.addCard(name: name, cutDay: cutDay, paymentDays: paymentDays)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Añadir Tarjeta")
            .navigationBarItems(trailing: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

