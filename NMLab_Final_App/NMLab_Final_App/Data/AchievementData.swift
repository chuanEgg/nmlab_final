//
//  AchievementData.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/03.
//

import Foundation

struct Achievement: Identifiable {
  let id: String
  let title: String
  let description: String
  let icon: String
  let rarity: AchievementRarity
  let isUnlocked: Bool
  let unlockedDate: Date?
  
  init(id: String, title: String, description: String, icon: String, rarity: AchievementRarity, isUnlocked: Bool, unlockedDate: Date? = nil) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.rarity = rarity
    self.isUnlocked = isUnlocked
    self.unlockedDate = unlockedDate
  }
}

enum AchievementRarity: String, CaseIterable {
  case common = "Common"
  case rare = "Rare"
  case epic = "Epic"
  case legendary = "Legendary"
  
  var color: String {
    switch self {
    case .common: return "gray"
    case .rare: return "blue"
    case .epic: return "purple"
    case .legendary: return "orange"
    }
  }
  
  var iconColor: String {
    switch self {
    case .common: return "gray"
    case .rare: return "blue"
    case .epic: return "purple"
    case .legendary: return "orange"
    }
  }
}

