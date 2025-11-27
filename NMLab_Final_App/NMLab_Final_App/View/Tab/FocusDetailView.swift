//
//  FocusDetailView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/27.
//
import SwiftUI

struct FocusDetailView: View {
  let focusData: FocusData

  var body: some View {
    List {
      Section("Summary") {
        detailRow(title: "User", value: focusData.username)
        detailRow(title: "Level", value: "\(focusData.level)")
        detailRow(title: "Play Time", value: formattedPlayTime(from: focusData))
        detailRow(title: "Score", value: "\(focusData.score)")
      }

      Section("Sessions") {
        if focusData.sessions.isEmpty {
          Text("No recorded sessions.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(focusData.sessions) { session in
            HStack(spacing: 4) {
              Text(sessionRangeText(for: session))
                .font(.headline)
                .fontWeight(.semibold)
              Spacer()
              Text(sessionDurationText(for: session))
//                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
          }
        }
      }
    }
//    .navigationTitle("\(focusData.username) Detail")
    .navigationTitle("Focus Detail")

  }

  private func detailRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
    }
  }

  private let sessionDisplayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd HH:mm"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  private let sessionDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  private func sessionRangeText(for session: FocusSession) -> String {
    let start = sessionDisplayFormatter.string(from: session.startDate)
    let end = sessionDisplayFormatter.string(from: session.endDate)
    return "\(start) - \(end)"
  }

  private func sessionDurationText(for session: FocusSession) -> String {
    sessionDurationFormatter.string(from: session.duration) ?? ""
  }
}

#Preview {
  UserDataView()
}
