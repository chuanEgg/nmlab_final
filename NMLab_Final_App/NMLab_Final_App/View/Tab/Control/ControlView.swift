//
//  ControlView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/8.
//

import Foundation
import SwiftUI
import UIKit

struct ControlView: View {
  @State private var status: FocusButtonStatus?
  @State private var statusMessage: String = ""
  @State private var isLoading = false
  @State private var latestPhoto: UIImage?
  @State private var isLoadingPhoto = false
  @State private var shouldStopAutoRefresh = false
  @State private var activeStartAt: Date?
  @State private var elapsedDisplay: String = "—"
  // Default user for fetching active session start; adjust if user selection is added.
  @State private var controlUsername: String = "Allen"

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        statusLabel
        elapsedTimerView
        photoView

        toggleButton
        refreshButton
//        if !statusMessage.isEmpty {
//          Text(statusMessage)
//            .font(.footnote)
//            .foregroundStyle(.secondary)
//        }
               

        Spacer()
      }
      .padding()
      .navigationTitle("Button Control")
      .task {
        await loadStatus()
        await loadPhoto()
      }
      .task {
        // Auto-refresh the photo every 5 seconds while the view is active
        shouldStopAutoRefresh = false
        while !shouldStopAutoRefresh {
          try? await Task.sleep(nanoseconds: 5_000_000_000)
          await loadPhoto(force: true)
        }
      }
      .refreshable {
        await loadStatus()
        await loadPhoto()
      }
      .task {
        // Lightweight timer to update elapsed label every second when active.
        shouldStopAutoRefresh = false
        while !shouldStopAutoRefresh {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          await MainActor.run { updateElapsedDisplay() }
        }
      }
      .onAppear {
        shouldStopAutoRefresh = false
      }
      .onDisappear {
        shouldStopAutoRefresh = true
      }
    }
  }

  private var statusLabel: some View {
    Group {
      if let status {
        Text(statusText(for: status.buttonStatus))
          .font(.title2.weight(.semibold))
          .padding()
          .frame(maxWidth: .infinity)
          // .background(status.buttonStatus == 1 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
          .background(status.buttonStatus == 1 ? Color.green.opacity(1) : Color.red.opacity(1))
          .clipShape(RoundedRectangle(cornerRadius: 24))
      } else if isLoading {
        ProgressView("Loading status...")
      } else {
        Text("Status unknown")
          .foregroundStyle(.secondary)
      }
    }
  }

  private var elapsedTimerView: some View {
    HStack {
      Spacer()
      Image(systemName: "clock")
        .foregroundStyle(.secondary)
      Text(activeStartAt == nil ? "Timer: inactive" : "Elapsed: \(elapsedDisplay)")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
      Spacer()
    }
    .padding(.horizontal, 4)
  }

  private var toggleButton: some View {
    Button {
      Task {
        await toggleStatus()
        await loadStatus()
      }
    } label: {
      Text("Toggle Button")
        .font(.title2.weight(.semibold))
        .padding(5)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .disabled(isLoading)
  }

  private var refreshButton: some View {
    Button {
      Task {
        await loadStatus(force: true)
        await loadPhoto(force: true)
      }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
    .disabled(isLoading)
  }

  private var photoView: some View {
    Group {
      if isLoadingPhoto {
        if let latestPhoto {
          Image(uiImage: latestPhoto)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 250)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 4)
        } else {
          ProgressView("Loading photo...")
        }
      } else if let latestPhoto {
        Image(uiImage: latestPhoto)
          .resizable()
          .scaledToFit()
          .frame(maxHeight: 250)
          .clipShape(RoundedRectangle(cornerRadius: 24))
          .shadow(radius: 4)
      } else {
        Text("No photo available")
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
  }

}

extension ControlView {
  func statusText(for value: Int) -> String {
    value == 1 ? "Button Status: ON" : "Button Status: OFF"
  }

  @MainActor
  func loadStatus(force: Bool = false) async {
    guard !isLoading || force else { return }
    isLoading = true
    statusMessage = "Loading..."

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      getFocusStatus { result in
        defer {
          isLoading = false
          continuation.resume()
        }
        switch result {
        case .success(let newStatus):
          status = newStatus
          statusMessage = "Updated just now"
          syncActiveStart(from: newStatus)
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
      }
    }
  }

  @MainActor
  func toggleStatus() async {
    guard !isLoading else { return }
    isLoading = true
    statusMessage = "Toggling..."

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      toggleFocusStatus { result in
        defer {
          isLoading = false
          continuation.resume()
        }
        switch result {
        case .success(let newStatus):
          status = newStatus
          statusMessage = "Toggled successfully"
          syncActiveStart(from: newStatus)
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
      }
    }
  }

  @MainActor
  func loadPhoto(force: Bool = false) async {
    guard !isLoadingPhoto || force else { return }
    isLoadingPhoto = true

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      fetchLatestPhoto { result in
        defer {
          isLoadingPhoto = false
          continuation.resume()
        }
        switch result {
        case .success(let image):
          latestPhoto = image
        case .failure:
          latestPhoto = nil
        }
      }
    }
  }

  @MainActor
  func syncActiveStart(from status: FocusButtonStatus) {
    if status.buttonStatus == 1 {
      if activeStartAt == nil {
        Task {
          let start = await fetchActiveSessionStart()
          await MainActor.run {
            activeStartAt = start ?? Date()
            updateElapsedDisplay()
          }
        }
        return
      }
    } else {
      activeStartAt = nil
      elapsedDisplay = "—"
    }
    updateElapsedDisplay()
  }

  func fetchActiveSessionStart() async -> Date? {
    await withCheckedContinuation { (continuation: CheckedContinuation<Date?, Never>) in
      getFocusData(user: controlUsername) { result in
        switch result {
        case .success(let data):
          if let ongoing = data.sessions.first(where: { $0.isOngoing }) {
            continuation.resume(returning: ongoing.startDate)
          } else {
            continuation.resume(returning: nil)
          }
        case .failure:
          continuation.resume(returning: nil)
        }
      }
    }
  }

  @MainActor
  func updateElapsedDisplay() {
    guard let start = activeStartAt else {
      elapsedDisplay = "—"
      return
    }
    let elapsed = Date().timeIntervalSince(start)
    if let formatted = sessionDurationFormatter.string(from: elapsed) {
      elapsedDisplay = formatted
    } else {
      elapsedDisplay = "—"
    }
  }
}



#Preview {
  ControlView()
}
