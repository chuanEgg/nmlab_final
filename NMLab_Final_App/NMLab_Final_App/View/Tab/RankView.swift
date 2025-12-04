//
//  RankView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import SwiftUI

struct RankView: View {
  @State private var ranks: [FocusRankData] = []
  @State private var statusMessage: String = "Pull to refresh."
  @State private var isLoading = false
  @State private var lastUpdatedAt: Date? = nil

  var body: some View {
    NavigationStack {
      List {
        ForEach(Array(ranks.enumerated()), id: \.element.id) { index, entry in
          NavigationLink {
            RankUserDetailView(username: entry.username)
          } label: {
            HStack {
              Text("\(index + 1).")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 32, alignment: .leading)
                .padding(.leading, 5)
              VStack(alignment: .leading) {
                Text(entry.username)
                  .font(.headline)
                Text("Score: \(entry.score)")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              if index == 0 {
                Image(systemName: "crown.fill")
                  .foregroundColor(.yellow)
              }
            }
          }
        }

        Section(statusMessage){}
      }
      .overlay {
        if ranks.isEmpty && isLoading {
          ProgressView("Loading ranks...")
        }
      }
      .refreshable {
        await fetchRanks()
      }
      .navigationTitle("Focus Rank")
//      .task(fetchRanks)
      .onAppear{
        Task {
          await fetchRanks()
        }
      }
      //這邊用onAppear是為了不會讓他一直加載，不然會很卡
    }
  }

  private func fetchRanks() async {
    guard !isLoading else { return }
    isLoading = true
    statusMessage = "Loading..."

    getFocusRank { result in
      defer { isLoading = false }
      switch result {
      case .success(let entries):
        ranks = entries.sorted { $0.score > $1.score }
        lastUpdatedAt = Date()
        statusMessage = formattedUpdateStatus(lastUpdatedAt: lastUpdatedAt)
      case .failure(let error):
        statusMessage = error.localizedDescription
      }
    }
  }
}

#Preview {
  RankView()
}
