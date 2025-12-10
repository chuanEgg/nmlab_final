//
//  FocusDetailListView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/3.
//

import SwiftUI

struct FocusDetailListView: View {
  let focusData: FocusData
  var body: some View {
      NavigationStack {
        List {
          Section("Summary") {
            detailRow(title: "User", value: focusData.username)
            detailRow(title: "Level", value: "\(focusData.level)")
            detailRow(title: "Play Time", value: formattedPlayTime(from: focusData))
            detailRow(title: "Total Score", value: "\(focusData.score)")
          }
          Section("Sessions") {
            if focusData.sessions.isEmpty {
              Text("No recorded sessions.")
                .foregroundStyle(.secondary)
            } else {
              ForEach(Array(focusData.sessions.enumerated()), id: \.element.id) { index, session in
                HStack(spacing: 6) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(sessionRangeText(for: session))
                      .font(.headline)
                      .fontWeight(.semibold)
                    Text("Score: \(sessionScoreText(at: index))")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text(sessionDurationText(for: session))
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
              }
            }
          }
        }
      }
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
  }

  private func detailRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 4)
  }

  private func sessionRangeText(for session: FocusSession) -> String {
    let start = sessionDisplayFormatter.string(from: session.startDate)
    if session.isOngoing {
      return "\(start) - Now"
    }
    let end = sessionDisplayFormatter.string(from: session.endDate)
    return "\(start) - \(end)"
  }

  private func sessionDurationText(for session: FocusSession) -> String {
    if session.isOngoing {
      let elapsed = Date().timeIntervalSince1970 - session.startTime
      let formatted = sessionDurationFormatter.string(from: elapsed) ?? ""
      return formatted.isEmpty ? "Ongoing" : "Ongoing · \(formatted)"
    }
    return sessionDurationFormatter.string(from: session.duration) ?? ""
  }
  
  private func sessionScoreText(at index: Int) -> String {
    if index < focusData.sessionScores.count {
      return "\(focusData.sessionScores[index])"
    }
    return "N/A"
  }
}

#Preview {
  UserDataView()
}
