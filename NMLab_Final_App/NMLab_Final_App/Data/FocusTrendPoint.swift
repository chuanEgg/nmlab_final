//
//  FocusTrendPoint.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/3.
//
import Foundation

struct FocusTrendPoint: Identifiable {
  let id = UUID()
  let date: Date
  let durationSeconds: Int

  var durationMinutes: Double {
    Double(durationSeconds) / 60.0
  }

  var shortDurationLabel: String {
    formatDuration(TimeInterval(durationSeconds))
  }
}
