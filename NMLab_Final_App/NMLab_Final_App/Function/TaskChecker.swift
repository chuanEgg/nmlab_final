//
//  TaskChecker.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/03.
//

import Foundation

func generateTasks(from focusData: FocusData) -> [FocusTask] {
  let totalSessions = focusData.sessions.count
//  let totalPlayTimeHours = Int(totalPlayTimeSeconds(from: focusData) / 3600)
  let totalPlayTimeMinutes = Int(totalPlayTimeSeconds(from: focusData) / 60)
  let currentLevel = focusData.level
  let currentScore = focusData.score
  
  // Calculate streak (consecutive days with sessions)
  let streak = calculateStreak(from: focusData.sessions)
  
  return [
    // Session tasks
    FocusTask(
      id: "task_sessions_1",
      title: "First Steps",
      description: "Complete your first focus session",
      icon: "1.circle.fill",
      targetValue: 1,
      currentValue: totalSessions,
      reward: "50 pts",
      category: .sessions
    ),
    FocusTask(
      id: "task_sessions_5",
      title: "Getting Started",
      description: "Complete 5 focus sessions",
      icon: "5.circle.fill",
      targetValue: 5,
      currentValue: totalSessions,
      reward: "200 pts",
      category: .sessions
    ),
    FocusTask(
      id: "task_sessions_10",
      title: "Dedicated Learner",
      description: "Complete 10 focus sessions",
      icon: "10.circle.fill",
      targetValue: 10,
      currentValue: totalSessions,
      reward: "500 pts",
      category: .sessions
    ),
    FocusTask(
      id: "task_sessions_25",
      title: "Focused Champion",
      description: "Complete 25 focus sessions",
      icon: "25.circle.fill",
      targetValue: 25,
      currentValue: totalSessions,
      reward: "1000 pts",
      category: .sessions
    ),
    
    // Time tasks
    FocusTask(
      id: "task_time_30min",
      title: "Half Hour Focus",
      description: "Accumulate 30 minutes of focus time",
      icon: "clock.fill",
      targetValue: 30,
      currentValue: totalPlayTimeMinutes,
      reward: "100 pts",
      category: .time
    ),
    FocusTask(
      id: "task_time_2h",
      title: "Two Hour Milestone",
      description: "Accumulate 2 hours of focus time",
      icon: "clock.badge.fill",
      targetValue: 120,
      currentValue: totalPlayTimeMinutes,
      reward: "300 pts",
      category: .time
    ),
    FocusTask(
      id: "task_time_10h",
      title: "Ten Hour Master",
      description: "Accumulate 10 hours of focus time",
      icon: "clock.arrow.circlepath",
      targetValue: 600,
      currentValue: totalPlayTimeMinutes,
      reward: "1000 pts",
      category: .time
    ),
    FocusTask(
      id: "task_time_50h",
      title: "Fifty Hour Legend",
      description: "Accumulate 50 hours of focus time",
      icon: "clock.badge.checkmark",
      targetValue: 3000,
      currentValue: totalPlayTimeMinutes,
      reward: "5000 pts",
      category: .time
    ),
    
    // Score tasks
    FocusTask(
      id: "task_score_100",
      title: "Century Score",
      description: "Reach 100 points",
      icon: "star.fill",
      targetValue: 100,
      currentValue: currentScore,
      reward: "Bonus 50 pts",
      category: .score
    ),
    FocusTask(
      id: "task_score_1000",
      title: "Thousand Points",
      description: "Reach 1,000 points",
      icon: "star.circle.fill",
      targetValue: 1000,
      currentValue: currentScore,
      reward: "Bonus 200 pts",
      category: .score
    ),
    FocusTask(
      id: "task_score_10000",
      title: "Ten Thousand Club",
      description: "Reach 10,000 points",
      icon: "star.square.fill",
      targetValue: 10000,
      currentValue: currentScore,
      reward: "Bonus 1000 pts",
      category: .score
    ),
    
    // Level tasks
    FocusTask(
      id: "task_level_5",
      title: "Level 5",
      description: "Reach level 5",
      icon: "arrow.up.circle.fill",
      targetValue: 5,
      currentValue: currentLevel,
      reward: "150 pts",
      category: .level
    ),
    FocusTask(
      id: "task_level_10",
      title: "Level 10",
      description: "Reach level 10",
      icon: "arrow.up.circle.fill",
      targetValue: 10,
      currentValue: currentLevel,
      reward: "300 pts",
      category: .level
    ),
    FocusTask(
      id: "task_level_25",
      title: "Level 25",
      description: "Reach level 25",
      icon: "arrow.up.circle.fill",
      targetValue: 25,
      currentValue: currentLevel,
      reward: "750 pts",
      category: .level
    ),
    
    // Streak tasks
    FocusTask(
      id: "task_streak_3",
      title: "Three Day Streak",
      description: "Maintain a 3-day focus streak",
      icon: "flame.fill",
      targetValue: 3,
      currentValue: streak,
      reward: "200 pts",
      category: .streak
    ),
    FocusTask(
      id: "task_streak_7",
      title: "Week Warrior",
      description: "Maintain a 7-day focus streak",
      icon: "flame.fill",
      targetValue: 7,
      currentValue: streak,
      reward: "500 pts",
      category: .streak
    ),
    FocusTask(
      id: "task_streak_30",
      title: "Monthly Master",
      description: "Maintain a 30-day focus streak",
      icon: "flame.fill",
      targetValue: 30,
      currentValue: streak,
      reward: "2000 pts",
      category: .streak
    ),
  ]
}

private func calculateStreak(from sessions: [FocusSession]) -> Int {
  guard !sessions.isEmpty else { return 0 }
  
  let calendar = Calendar.current
  var uniqueDays = Set<String>()
  
  for session in sessions {
    let dayString = calendar.startOfDay(for: session.startDate)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    uniqueDays.insert(formatter.string(from: dayString))
  }

  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  let sortedDays = uniqueDays.sorted(by: >)
//  guard let mostRecentDayString = sortedDays.first,
//        let mostRecentDay = formatter.date(from: mostRecentDayString) else {
//    return 0
//  }

  guard sortedDays.first != nil else {
    return 0
  }

  var streak = 0
  var currentDate = calendar.startOfDay(for: Date())
  let formatter2 = DateFormatter()
  formatter2.dateFormat = "yyyy-MM-dd"
  
  while true {
    let dayString = formatter2.string(from: currentDate)
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

