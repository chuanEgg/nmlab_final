//
//  UserDataView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import SwiftUI

struct UserDataView: View {
  @StateObject private var dataManager = UserDataManager()
  @State private var hasLoadedOnce = false


  var body: some View {
    NavigationStack {
      List {
        Section {
        } header: {
          Text("Welcome Back, \(dataManager.username)")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.primary)
        }

        Section("Your Record") {
          if let focusData = dataManager.focusData {
            VStack(spacing: 16) {
              focusSummaryLabel(for: focusData)

              FocusDetailChartView(focusData: focusData)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            }

          } else {
            Text("No data")
              .foregroundStyle(.secondary)
          }
        }
        Section {
          if let focusData = dataManager.focusData {
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

        Section(dataManager.statusMessage) {
        }
      }
      .navigationTitle("Focus Record")
      .listSectionSpacing(10)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            if dataManager.isLoadingUsers {
              ProgressView("Loading users...")
            } else if dataManager.availableUsers.isEmpty {
              Button("No users available", action: {})
                .disabled(true)
            } else {
              ForEach(dataManager.availableUsers, id: \.self) { user in
                Button(user) {
                  dataManager.switchToUser(user)
                }
              }
            }
            Divider()
            Button {
              Task {
                await dataManager.fetchUserList(autoSelect: false)
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
            await dataManager.initialLoad()
          }
        }
      }
      .onChange(of: dataManager.username) { _, _ in
        dataManager.fetchData()
      }
      .refreshable {
        dataManager.fetchData()
      }
    }
  }

  private func focusDataRows(for data: FocusData) -> [(title: String, value: String)] {
    [
      ("Level", "\(data.level)"),
      ("Play Time", formattedPlayTime(from: data)),
      ("Score", "\(data.score)")
    ]
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


