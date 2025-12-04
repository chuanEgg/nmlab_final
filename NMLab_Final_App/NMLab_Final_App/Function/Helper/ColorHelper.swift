//
//  ColorHelper.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/5.
//
import Foundation
import SwiftUI

func colorForCategory(_ category: TaskCategory) -> Color {
  switch category {
  case .sessions: return .blue
  case .time: return .green
  case .score: return .yellow
  case .level: return .purple
  case .streak: return .orange
  }
}

func colorForRarity(_ rarity: AchievementRarity) -> Color {
  switch rarity {
  case .common: return .gray
  case .rare: return .blue
  case .epic: return .purple
  case .legendary: return .orange
  }
}
