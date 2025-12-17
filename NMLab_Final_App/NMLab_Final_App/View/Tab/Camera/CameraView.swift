//
//  ControlView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/8.
//

import Foundation
import SwiftUI
import UIKit

struct CameraView: View {
  @State private var status: FocusButtonStatus?
  @State private var statusMessage: String = "Loading..."
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
        photoView
        statusInfoCard
        controlsButtons
        Spacer()
      }
      .padding()
      .navigationTitle("Camera")
      .toolbar {
        NavigationLink {
          BaseURLSettingsView {
            Task {
              await loadStatus(force: true)
              await loadPhoto(force: true)
              await loadTrackerStatusMessage()
            }
          }
        } label: {
          Image(systemName: "gearshape")
        }
      }
      .task {
        await loadStatus()
        await loadPhoto()
      }
      .task {
        // Auto-refresh the photo every 0.5 seconds while the view is active
        shouldStopAutoRefresh = false
        while !shouldStopAutoRefresh {
          try? await Task.sleep(nanoseconds: 200_000_000)
          await loadPhoto(force: true)
          await loadTrackerStatusMessage()
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

  private var controlsButtons: some View {
    HStack(spacing: 12) {
      toggleButton
      refreshButton
    }
  }

  private var statusInfoCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: "face.smiling")
        Text(statusMessage)
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)
        Spacer()
      }

      Divider()

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: "clock")
          .foregroundStyle(.secondary)
        Text(activeStartAt == nil ? "Timer: Inactive" : "Has focused: \(elapsedDisplay)")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)
        Spacer()
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(uiColor: .secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(radius: 4)
  }

  private var toggleButton: some View {
    Button {
      Task {
        await toggleStatus()
        await loadStatus()
      }
    } label: {
      toggleButtonTitle
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, minHeight: 52)
    .background(toggleButtonColor)
    .foregroundStyle(.white)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
    )
    .disabled(isLoading)
  }

  private var toggleButtonTitle: some View {
    if let status, status.buttonStatus == 1 {
      HStack {
        Image(systemName: "stop.fill")
          .resizable()
          .scaledToFit()
          .frame(height: 18)
        Text("Stop")
          .font(.title2.weight(.semibold))
      }
    } else {
      HStack {
        Image(systemName: "play.fill")
          .resizable()
          .scaledToFit()
          .frame(height: 18)
        Text("Start")
          .font(.title2.weight(.semibold))
      }
    }
  }

  private var toggleButtonColor: Color {
    if let status, status.buttonStatus == 1 {
      return Color.red.opacity(1)
    }
    return Color.green.opacity(1)
  }

  private var refreshButton: some View {
    Button {
      Task {
        await loadStatus(force: true)
        await loadPhoto(force: true)
      }
    } label: {
      HStack {
        Image(systemName: "arrow.clockwise")
          .resizable()
          .scaledToFit()
          .frame(height: 18)
        Text("Refresh")
          .font(.title2.weight(.semibold))
      }
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, minHeight: 52)
    .background(Color.accentColor)
    .foregroundStyle(.white)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
    )
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
//          ProgressView("Loading photo...")
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

extension CameraView {
  func statusText(for value: Int) -> String {
    value == 1 ? "Camera Status: ON" : "Camera Status: OFF"
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
          statusMessage = "Fetching tracker status..."
          syncActiveStart(from: newStatus)
          Task { await loadTrackerStatusMessage() }
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

  @MainActor
  func loadTrackerStatusMessage() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      getTrackerStatus { result in
        switch result {
        case .success(let message):
          statusMessage = message
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
        continuation.resume()
      }
    }
  }
}


#Preview {
  CameraView()
}
