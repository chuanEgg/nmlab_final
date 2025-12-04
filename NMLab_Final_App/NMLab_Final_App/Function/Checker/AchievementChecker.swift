//
//  AchievementChecker.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/03.
//

import Foundation

func generateAchievements(from focusData: FocusData) -> [Achievement] {
  let totalSessions = focusData.sessions.count
  let totalPlayTimeHours = Int(totalPlayTimeSeconds(from: focusData) / 3600)
  let currentLevel = focusData.level
  let currentScore = focusData.score
  
  // Calculate streak
  let streak = calculateStreak(from: focusData.sessions)
  
  // Find first session date
  let firstSessionDate = focusData.sessions.min(by: { $0.startTime < $1.startTime })?.startDate
  
  return [
    // First session achievement
    Achievement(
      id: "ach_first_session",
      title: "First Focus",
      description: "Complete your very first focus session",
      icon: "sparkles",
      rarity: .common,
      isUnlocked: totalSessions >= 1,
      unlockedDate: firstSessionDate
    ),
    
    // Session milestones
    Achievement(
      id: "ach_10_sessions",
      title: "Decade of Focus",
      description: "Complete 10 focus sessions",
      icon: "calendar.badge.plus",
      rarity: .rare,
      isUnlocked: totalSessions >= 10,
      unlockedDate: totalSessions >= 10 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_50_sessions",
      title: "Half Century",
      description: "Complete 50 focus sessions",
      icon: "calendar.badge.exclamationmark",
      rarity: .epic,
      isUnlocked: totalSessions >= 50,
      unlockedDate: totalSessions >= 50 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_100_sessions",
      title: "Centurion",
      description: "Complete 100 focus sessions",
      icon: "calendar.badge.checkmark",
      rarity: .legendary,
      isUnlocked: totalSessions >= 100,
      unlockedDate: totalSessions >= 100 ? firstSessionDate : nil
    ),
    
    // Time achievements
    Achievement(
      id: "ach_1_hour",
      title: "Hour Power",
      description: "Accumulate 1 hour of focus time",
      icon: "clock.fill",
      rarity: .common,
      isUnlocked: totalPlayTimeHours >= 1,
      unlockedDate: totalPlayTimeHours >= 1 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_10_hours",
      title: "Ten Hour Hero",
      description: "Accumulate 10 hours of focus time",
      icon: "clock.badge.fill",
      rarity: .rare,
      isUnlocked: totalPlayTimeHours >= 10,
      unlockedDate: totalPlayTimeHours >= 10 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_100_hours",
      title: "Century of Hours",
      description: "Accumulate 100 hours of focus time",
      icon: "clock.arrow.circlepath",
      rarity: .epic,
      isUnlocked: totalPlayTimeHours >= 100,
      unlockedDate: totalPlayTimeHours >= 100 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_1000_hours",
      title: "Master of Time",
      description: "Accumulate 1,000 hours of focus time",
      icon: "clock.badge.checkmark",
      rarity: .legendary,
      isUnlocked: totalPlayTimeHours >= 1000,
      unlockedDate: totalPlayTimeHours >= 1000 ? firstSessionDate : nil
    ),
    
    // Level achievements
    Achievement(
      id: "ach_level_10",
      title: "Level 10",
      description: "Reach level 10",
      icon: "arrow.up.circle.fill",
      rarity: .rare,
      isUnlocked: currentLevel >= 10,
      unlockedDate: currentLevel >= 10 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_level_50",
      title: "Level 50",
      description: "Reach level 50",
      icon: "arrow.up.circle.fill",
      rarity: .epic,
      isUnlocked: currentLevel >= 50,
      unlockedDate: currentLevel >= 50 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_level_100",
      title: "Century Level",
      description: "Reach level 100",
      icon: "arrow.up.circle.fill",
      rarity: .legendary,
      isUnlocked: currentLevel >= 100,
      unlockedDate: currentLevel >= 100 ? firstSessionDate : nil
    ),
    
    // Score achievements
    Achievement(
      id: "ach_score_1000",
      title: "Thousandaire",
      description: "Reach 1,000 points",
      icon: "star.fill",
      rarity: .rare,
      isUnlocked: currentScore >= 1000,
      unlockedDate: currentScore >= 1000 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_score_10000",
      title: "Ten Thousandaire",
      description: "Reach 10,000 points",
      icon: "star.circle.fill",
      rarity: .epic,
      isUnlocked: currentScore >= 10000,
      unlockedDate: currentScore >= 10000 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_score_100000",
      title: "Hundred Thousandaire",
      description: "Reach 100,000 points",
      icon: "star.square.fill",
      rarity: .legendary,
      isUnlocked: currentScore >= 100000,
      unlockedDate: currentScore >= 100000 ? firstSessionDate : nil
    ),
    
    // Streak achievements
    Achievement(
      id: "ach_streak_7",
      title: "Week Warrior",
      description: "Maintain a 7-day focus streak",
      icon: "flame.fill",
      rarity: .rare,
      isUnlocked: streak >= 7,
      unlockedDate: streak >= 7 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_streak_30",
      title: "Monthly Master",
      description: "Maintain a 30-day focus streak",
      icon: "flame.fill",
      rarity: .epic,
      isUnlocked: streak >= 30,
      unlockedDate: streak >= 30 ? firstSessionDate : nil
    ),
    Achievement(
      id: "ach_streak_100",
      title: "Century Streak",
      description: "Maintain a 100-day focus streak",
      icon: "flame.fill",
      rarity: .legendary,
      isUnlocked: streak >= 100,
      unlockedDate: streak >= 100 ? firstSessionDate : nil
    ),
  ]
}

private func calculateStreak(from sessions: [FocusSession]) -> Int {
  guard !sessions.isEmpty else { return 0 }
  
  let calendar = Calendar.current
  var uniqueDays = Set<String>()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  
  for session in sessions {
    let dayString = formatter.string(from: session.startDate)
    uniqueDays.insert(dayString)
  }
  
  let sortedDays = uniqueDays.sorted(by: >)
  
  guard sortedDays.first != nil else {
    return 0
  }

  var streak = 0
  var currentDate = calendar.startOfDay(for: Date())
  
  while true {
    let dayString = formatter.string(from: currentDate)
    if sortedDays.contains(dayString) {
      streak += 1
      if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
        currentDate = calendar.startOfDay(for: previousDay)
      } else {
        break
      }
    } else {
      break
    }
  }
  
  return streak
}

