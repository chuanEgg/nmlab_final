//
//  CameraSessionSummary.swift
//  NMLab_Final_App
//
//  Created by Cursor on 2025/12/17.
//

import Foundation

/// Convenience container for summarizing the last completed focus session.
struct SessionSummary {
  let duration: String?
  let score: Int?
}

/// Finds the latest completed session (non-ongoing) and returns its duration text and score.
/// - Parameter data: Fetched `FocusData` for a user.
/// - Returns: `SessionSummary` with formatted duration and matching score if present.
func latestCompletedSessionSummary(from data: FocusData) -> SessionSummary {
  guard let index = data.sessions.lastIndex(where: { !$0.isOngoing }) else {
    return SessionSummary(duration: nil, score: nil)
  }

  let session = data.sessions[index]
  let durationText = sessionDurationFormatter.string(from: session.duration)
  let score = data.sessionScores.indices.contains(index) ? data.sessionScores[index] : nil

  return SessionSummary(duration: durationText, score: score)
}

