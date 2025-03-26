//
//  ColorPalette.swift
//  CreditCardCalendar
//
//  Created by Zaid Garcia Casas on 26/03/25.
//
// Extensión temporal para ColorPalette
// ColorPalette.swift
import SwiftUI

// ⚠️ Elimina la palabra 'private' ⚠️
struct ColorPalette {
    static let green = "4CAF50"
    static let yellow = "FFC107"
    static let orange = "FF9800"
    static let red = "F44336"
    static let blue = "2196F3"
    static let purple = "9C27B0"
    static let teal = "009688"
    static let indigo = "3F51B5"
    
    static func allColors() -> [String] {
        return [green, yellow, orange, red, blue, purple, teal, indigo]
    }
    
    static func randomColor() -> String {
        return allColors().randomElement() ?? blue
    }
}
