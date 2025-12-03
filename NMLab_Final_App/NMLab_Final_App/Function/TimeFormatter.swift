//
//  TimeFormatter.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/27.
//

import Foundation

// Formats the status message as "Updated X minutes ago." with a minimum unit of minutes.
func formattedUpdateStatus(reference: Date = Date(), lastUpdatedAt: Date?) -> String {
  guard let last = lastUpdatedAt else { return "Scroll to fetch data." }
  let seconds = reference.timeIntervalSince(last)
  if seconds < 60 {
    return "Updated just now."
  }
  let minutes = Int(seconds / 60)
  if minutes < 60 {
    return "Updated \(minutes) minute\(minutes == 1 ? "" : "s") ago."
  }
  let hours = Int(Double(minutes) / 60.0)
  if hours < 24 {
    let remainingMinutes = minutes % 60
    if remainingMinutes == 0 {
      return "Updated \(hours) hour\(hours == 1 ? "" : "s") ago."
    } else {
      return "Updated \(hours) hour\(hours == 1 ? "" : "s") \(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s") ago."
    }
  }
  let days = Int(Double(hours) / 24.0)
  return "Updated \(days) day\(days == 1 ? "" : "s") ago."
}

// Computes and formats total play time leveraging session data, with a fallback to raw play-time slices.
func formattedPlayTime(from data: FocusData) -> String {
  let totalSeconds = totalPlayTimeSeconds(from: data)
  return formatDuration(totalSeconds)
}

// Resolves the most reliable play-time total (seconds) for a user.
func totalPlayTimeSeconds(from data: FocusData) -> TimeInterval {
  // Sum positive session durations (in seconds)
  let totalSecondsFromSessions: TimeInterval = data.sessions.reduce(0) { partial, session in
    let d = session.duration
    return partial + max(0, d)
  }

  if totalSecondsFromSessions > 0 {
    return totalSecondsFromSessions
  }

  // Fallback to the backend-supplied slices (assumed seconds per segment)
  return TimeInterval(data.totalPlayTimeSeconds)
}

// Formats a duration in seconds into a human-friendly string like "1h 24m" or "12m".
func formatDuration(_ seconds: TimeInterval) -> String {
  let totalMinutes = Int(seconds / 60)
  let hours = totalMinutes / 60
  let minutes = totalMinutes % 60

  if hours > 0 && minutes > 0 {
    return "\(hours)h \(minutes)m"
  } else if hours > 0 {
    return "\(hours)h"
  } else {
    return "\(minutes)m"
  }
}

let sessionDisplayFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MM/dd HH:mm"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter
}()

let sessionDurationFormatter: DateComponentsFormatter = {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.hour, .minute]
  formatter.unitsStyle = .abbreviated
  return formatter
  }()
