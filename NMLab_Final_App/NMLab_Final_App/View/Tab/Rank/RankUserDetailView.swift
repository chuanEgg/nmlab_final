//
//  RankUserDetailView.swift
//  NMLab_Final_App
//
//  Created by Cursor on 2025/12/04.
//

import SwiftUI

struct RankUserDetailView: View {
  let username: String

  @State private var focusData: FocusData?
  @State private var statusMessage: String = "Loading..."
  @State private var isLoading = false
  @State private var lastUpdatedAt: Date? = nil

  var body: some View {
    Group {
      if let focusData {
        ScrollView {
          VStack(spacing: 16) {
            FocusDetailChartView(focusData: focusData)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                  .fill(Color(.secondarySystemBackground))
              )

            FocusDetailListView(focusData: focusData)
          }
          .padding()
        }
      } else {
        VStack(spacing: 12) {
          if isLoading {
            ProgressView("Loading...")
          } else {
            Text(statusMessage)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      }
    }
    // Intentionally no .navigationTitle to avoid showing a page title
    .task {
      fetchData()
    }
    .refreshable {
      fetchData()
    }
  }

  private func fetchData() {
    statusMessage = "Loading..."
    isLoading = true
    focusData = nil

    getFocusData(user: username) { result in
      switch result {
      case .success(let data):
        focusData = data
        lastUpdatedAt = Date()
        statusMessage = formattedUpdateStatus(lastUpdatedAt: lastUpdatedAt)
      case .failure(let error):
        statusMessage = error.localizedDescription
      }

      isLoading = false
    }
  }
}

#Preview {
  RankUserDetailView(username: "PreviewUser")
}


