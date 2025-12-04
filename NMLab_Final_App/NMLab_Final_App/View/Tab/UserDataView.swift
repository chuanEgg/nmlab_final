//
//  UserDataView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import SwiftUI

struct UserDataView: View {
  @AppStorage("currentUsername") private var username = "Allen"
  @State private var availableUsers: [String] = []
  @State private var focusData: FocusData?
  @State private var statusMessage: String = "Scroll to fetch data."
  @State private var isLoadingUsers = false
  @State private var lastUpdatedAt: Date? = nil
  @State private var hasLoadedOnce = false


  var body: some View {
    NavigationStack {
      List {
        Section {
        } header: {
          Text("Welcome Back, \(username)")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.primary)
        }

        Section("Your Record") {
          if let focusData {
            VStack(spacing: 16) {
              focusSummaryLabel(for: focusData)

              FocusDetailChartView(focusData: focusData)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
//                .background(
//                  RoundedRectangle(cornerRadius: 20, style: .continuous)
//                    .fill(Color(.secondarySystemBackground))
//                )
            }

          } else {
            Text("No data")
              .foregroundStyle(.secondary)
          }
        }
        Section {
          if let focusData {
            NavigationLink {
              FocusDetailListView(focusData: focusData)
            } label: {
              Text("Details")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
          } else {
          }
        }

        Section(statusMessage) {
        }
      }
      .navigationTitle("Focus Record")
      .listSectionSpacing(10)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            if isLoadingUsers {
              ProgressView("Loading users...")
            } else if availableUsers.isEmpty {
              Button("No users available", action: {})
                .disabled(true)
            } else {
              ForEach(availableUsers, id: \.self) { user in
                Button(user) {
                  switchToUser(user)
                }
              }
            }
            Divider()
            Button {
              Task {
                await fetchUserList(autoSelect: false)
              }
            } label: {
              Label("Refresh users", systemImage: "arrow.clockwise")
            }
          } label: {
            Image(systemName: "person.fill")
          }
        }
      }
      .onAppear {
        if !hasLoadedOnce {
          hasLoadedOnce = true
          Task {
            await initialLoad()
          }
        }
      }
      .onChange(of: username) { _, _ in
        fetchData()
      }
      .refreshable {
        fetchData()
      }
    }
  }

  private func initialLoad() async {
    await fetchUserList(autoSelect: true)
    fetchData()
  }

  private func switchToUser(_ newUser: String) {
    guard username != newUser else { return }
    username = newUser
    fetchData()
  }

  private func focusDataRows(for data: FocusData) -> [(title: String, value: String)] {
    [
      ("Level", "\(data.level)"),
      ("Play Time", formattedPlayTime(from: data)),
      ("Score", "\(data.score)")
    ]
  }

  private func fetchData() {
    statusMessage = "Loading..."
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
    }
  }

  @MainActor
  private func fetchUserList(autoSelect: Bool) async {
    guard !isLoadingUsers else { return }
    isLoadingUsers = true

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      getFocusUsers { result in
        defer {
          isLoadingUsers = false
          continuation.resume()
        }
        switch result {
        case .success(let users):
          availableUsers = users.sorted()
          if autoSelect, !users.contains(username), let firstUser = users.first {
            username = firstUser
          }
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
      }
    }
  }

  // Formatter for displaying the first session date in the summary
  private static let firstSessionFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  // Returns a formatted string for the earliest session start date, if available
  private func firstSessionDateText(from data: FocusData) -> String? {
    guard let first = data.sessions.min(by: { $0.startTime < $1.startTime }) else { return nil }
    return UserDataView.firstSessionFormatter.string(from: first.startDate)
  }

  @ViewBuilder
  private func focusSummaryLabel(for data: FocusData) -> some View {
    HStack {
      Image(systemName: "graduationcap.circle")
        .resizable()
        .scaledToFit()
        .frame(maxHeight: 50)

      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 10) {
          Text("Lv."+"\(data.level)")
            .foregroundStyle(.secondary)
            .font(.title3.weight(.semibold))
          Spacer()
          if let firstText = firstSessionDateText(from: data) {
            Text(firstText)
              .foregroundStyle(.secondary)
              .font(.headline.weight(.semibold))
          }
        }
        HStack(spacing: 10) {
          Text(formattedPlayTime(from: data))
            .font(.title2.weight(.bold))
          Divider()
          Text("\(data.score)" + " pts")
            .font(.title2.weight(.bold))
          
        }
        .frame(height: 30)
      }
      .padding(.horizontal, 10)
    }
    .padding(5)
    .frame(maxWidth: .infinity, maxHeight: 70,alignment: .leading)
    .clipShape(RoundedRectangle(cornerRadius: 12))
//    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
  }
}

#Preview {
  UserDataView()
}

