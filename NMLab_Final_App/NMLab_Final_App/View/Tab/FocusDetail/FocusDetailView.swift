import Charts
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
    ScrollView {
      VStack(spacing: 16) {
        FocusDetailChartView(focusData: focusData)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .fill(Color(.systemBackground))
          )

        NavigationLink {
          FocusDetailListView(focusData: focusData)
        } label: {
          ListRowButtonLabel(title: "Details")
        }
      }
      .padding(.horizontal)
      .padding(.top, 12)
      .padding(.bottom, 24)
    }
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("Focus Detail")
  }
}

/// A reusable, list-style row that looks like a tappable Settings cell.
private struct ListRowButtonLabel: View {
  let title: String

  var body: some View {
    HStack {
      Text(title)
        .foregroundStyle(.primary)
      Spacer()
      Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 16)
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Capsule()
        .fill(Color(.systemBackground))
    )
    .overlay(
      Capsule()
        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
    )
    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

#Preview {
  NavigationStack {
    FocusDetailView(
      focusData: FocusData(
        id: "preview",
        username: "Preview",
        level: 1,
        playTimes: [3600, 5400, 1800],
        score: 100,
        sessions: []
      )
    )
  }
}
