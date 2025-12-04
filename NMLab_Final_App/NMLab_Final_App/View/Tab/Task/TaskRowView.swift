//
//  TaskRowView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/5.
//
import SwiftUI
import Foundation

struct TaskRowView: View {
  let task: FocusTask
  
  var body: some View {
    HStack(spacing: 16) {
      // Icon
      ZStack {
        Circle()
          .fill(colorForCategory(task.category).opacity(0.2))
          .frame(width: 50, height: 50)
        Image(systemName: task.icon)
          .foregroundStyle(colorForCategory(task.category))
          .font(.title3)
      }
      
      // Content
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(task.title)
            .font(.headline)
          if task.isCompleted {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
              .font(.subheadline)
          }
        }
        Text(task.description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        
        // Progress bar
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color(.systemGray5))
            RoundedRectangle(cornerRadius: 4)
              .fill(colorForCategory(task.category))
              .frame(width: geometry.size.width * task.progress)
          }
        }
        .frame(height: 6)
        
        HStack {
          Text(task.progressText)
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Text("Reward: \(task.reward)")
            .font(.caption)
            .foregroundStyle(colorForCategory(task.category))
            .fontWeight(.semibold)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    )
    .padding(.horizontal)
    .opacity(task.isCompleted ? 0.7 : 1.0)
  }
  
  private func colorForCategory(_ category: TaskCategory) -> Color {
    switch category {
    case .sessions: return .blue
    case .time: return .green
    case .score: return .yellow
    case .level: return .purple
    case .streak: return .orange
    }
  }
}
