//
//  ControlView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/8.
//

import SwiftUI

struct ControlView: View {
  @State private var status: FocusButtonStatus?
  @State private var statusMessage: String = ""
  @State private var isLoading = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        statusLabel
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
      .task { await loadStatus() }
      .refreshable { await loadStatus() }
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
          .clipShape(RoundedRectangle(cornerRadius: 12))
      } else if isLoading {
        ProgressView("Loading status...")
      } else {
        Text("Status unknown")
          .foregroundStyle(.secondary)
      }
    }
  }

  private var toggleButton: some View {
    Button {
      Task { await toggleStatus() }
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
      Task { await loadStatus(force: true) }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
    .disabled(isLoading)
  }

  private func statusText(for value: Int) -> String {
    value == 1 ? "Button Status: ON" : "Button Status: OFF"
  }

  @MainActor
  private func loadStatus(force: Bool = false) async {
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
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
      }
    }
  }

  @MainActor
  private func toggleStatus() async {
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
        case .failure(let error):
          statusMessage = error.localizedDescription
        }
      }
    }
  }
}

#Preview {
  ControlView()
}
