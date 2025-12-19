//
//  AchievementCardView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/5.
//
import SwiftUI
import Foundation

struct AchievementCardView: View {
  let achievement: Achievement
  
  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(colorForRarity(achievement.rarity).opacity(achievement.isUnlocked ? 0.2 : 0.1))
          .frame(width: 60, height: 60)
        Image(systemName: achievement.icon)
          .foregroundStyle(achievement.isUnlocked ? colorForRarity(achievement.rarity) : .gray)
          .font(.title2)
      }
      
      VStack(spacing: 4) {
        Text(achievement.title)
          .font(.caption)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
        
        if achievement.isUnlocked {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.caption2)
        } else {
          Text(achievement.rarity.rawValue)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(colorForRarity(achievement.rarity).opacity(achievement.isUnlocked ? 0.5 : 0.2), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    )
    .opacity(achievement.isUnlocked ? 1.0 : 0.6)
  }
  
  private func colorForRarity(_ rarity: AchievementRarity) -> Color {
    switch rarity {
    case .common: return .gray
    case .rare: return .blue
    case .epic: return .purple
    case .legendary: return .orange
    }
  }
}
