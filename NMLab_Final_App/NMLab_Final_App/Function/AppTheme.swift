//
//  AppTheme.swift
//  NMLab_Final_App
//
//  Central place to manage user-editable UI theme values,
//  such as the accent color.
//

import Foundation
import SwiftUI

enum AppTheme {
  // MARK: - Accent color

  private static let accentKey = "AppThemeAccentColor"

  enum AccentChoice: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case pink
    case purple

    var id: String { rawValue }

    var displayName: String {
      switch self {
      case .blue: return "Blue"
      case .green: return "Green"
      case .orange: return "Orange"
      case .pink: return "Pink"
      case .purple: return "Purple"
      }
    }
  }

  /// Current persisted accent choice.
  static var accentChoice: AccentChoice {
    get {
      if let stored = UserDefaults.standard.string(forKey: accentKey),
         let choice = AccentChoice(rawValue: stored) {
        return choice
      }
      return .blue
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: accentKey)
    }
  }

  /// The actual SwiftUI `Color` to use as accent.
  static var accentColor: Color {
    color(for: accentChoice)
  }

  static func color(for choice: AccentChoice) -> Color {
    switch choice {
    case .blue: return .blue
    case .green: return .green
    case .orange: return .orange
    case .pink: return .pink
    case .purple: return .purple
    }
  }
}

