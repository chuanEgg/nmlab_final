//
//  TaskData.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/03.
//

import Foundation

struct FocusTask: Identifiable {
  let id: String
  let title: String
  let description: String
  let icon: String
  let targetValue: Int
  let currentValue: Int
  let reward: String
  let category: TaskCategory
  
  var progress: Double {
    guard targetValue > 0 else { return 0 }
    return min(1.0, Double(currentValue) / Double(targetValue))
  }
  
  var isCompleted: Bool {
    currentValue >= targetValue
  }
  
  var progressText: String {
    "\(currentValue) / \(targetValue)"
  }
}

enum TaskCategory: String, CaseIterable {
  case sessions = "Sessions"
  case time = "Time"
  case score = "Score"
  case level = "Level"
  case streak = "Streak"
  
  var icon: String {
    switch self {
    case .sessions: return "calendar"
    case .time: return "clock"
    case .score: return "star"
    case .level: return "chart.line.uptrend.xyaxis"
    case .streak: return "flame"
    }
  }
  
  var color: String {
    switch self {
    case .sessions: return "blue"
    case .time: return "green"
    case .score: return "yellow"
    case .level: return "purple"
    case .streak: return "orange"
    }
  }
}

