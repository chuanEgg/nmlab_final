//
//  UserDataManager.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/05.
//

import Foundation
import SwiftUI
internal import Combine

/// Shared data management functions for views that need to fetch user data
@MainActor
class UserDataManager: ObservableObject {
  @Published var username: String {
    didSet {
      UserDefaults.standard.set(username, forKey: "currentUsername")
    }
  }
  @Published var availableUsers: [String] = []
  @Published var focusData: FocusData?
  @Published var statusMessage: String = "Scroll to fetch data."
  @Published var isLoadingUsers = false
  @Published var lastUpdatedAt: Date? = nil
  
  private var updateTimer: Timer?
  
  init() {
    self.username = UserDefaults.standard.string(forKey: "currentUsername") ?? "Allen"
  }
  
  deinit {
    updateTimer?.invalidate()
  }
  
  /// Starts a timer to update the status message periodically
  private func startUpdateTimer() {
    updateTimer?.invalidate()
    
    // Update immediately
    updateStatusMessage()
    
    // Then update every 30 seconds
    updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
      Task { @MainActor [weak self] in
        self?.updateStatusMessage()
      }
    }
  }
  
  /// Stops the update timer
  private func stopUpdateTimer() {
    updateTimer?.invalidate()
    updateTimer = nil
  }
  
  /// Updates the status message based on lastUpdatedAt
  private func updateStatusMessage() {
    guard let lastUpdated = lastUpdatedAt else {
      statusMessage = "Scroll to fetch data."
      return
    }
    statusMessage = formattedUpdateStatus(lastUpdatedAt: lastUpdated)
  }
  
  /// Initial load: fetches user list and then user data
  func initialLoad() async {
    await fetchUserList(autoSelect: true)
    fetchData()
  }
  
  /// Fetches the list of available users from the server
  func fetchUserList(autoSelect: Bool) async {
    guard !isLoadingUsers else { return }
    isLoadingUsers = true
    
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      getFocusUsers { [weak self] result in
        Task { @MainActor in
          defer { continuation.resume() }
          guard let self else { return }
          self.isLoadingUsers = false
          switch result {
          case .success(let users):
            self.availableUsers = users.sorted()
            if autoSelect, !users.contains(self.username), let firstUser = users.first {
              self.username = firstUser
            }
          case .failure(let error):
            self.statusMessage = error.localizedDescription
          }
        }
      }
    }
  }
  
  /// Fetches focus data for the current user
  func fetchData() {
    statusMessage = "Loading..."
    focusData = nil
    stopUpdateTimer()
    
    getFocusData(user: username) { [weak self] result in
      Task { @MainActor in
        guard let self else { return }
        switch result {
        case .success(let data):
          self.focusData = data
          self.lastUpdatedAt = Date()
          self.startUpdateTimer()
        case .failure(let error):
          self.statusMessage = error.localizedDescription
          self.stopUpdateTimer()
        }
      }
    }
  }
  
  /// Switches to a different user and fetches their data
  func switchToUser(_ newUser: String) {
    guard username != newUser else { return }
    username = newUser
    fetchData()
  }
}

/// Simplified data manager for TaskView (doesn't track lastUpdatedAt with formatted status)
@MainActor
class TaskDataManager: ObservableObject {
  @Published var username: String {
    didSet {
      UserDefaults.standard.set(username, forKey: "currentUsername")
    }
  }
  @Published var availableUsers: [String] = []
  @Published var focusData: FocusData?
  @Published var statusMessage: String = "Pull to refresh."
  @Published var isLoading = false
  @Published var isLoadingUsers = false
  
  init() {
    self.username = UserDefaults.standard.string(forKey: "currentUsername") ?? "Allen"
  }
  
  /// Initial load: fetches user list and then user data
  func initialLoad() async {
    await fetchUserList(autoSelect: true)
    fetchData()
  }
  
  /// Fetches the list of available users from the server
  func fetchUserList(autoSelect: Bool) async {
    guard !isLoadingUsers else { return }
    isLoadingUsers = true
    
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      getFocusUsers { [weak self] result in
        Task { @MainActor in
          defer { continuation.resume() }
          guard let self else { return }
          self.isLoadingUsers = false
          switch result {
          case .success(let users):
            self.availableUsers = users.sorted()
            if autoSelect, !users.contains(self.username), let firstUser = users.first {
              self.username = firstUser
            }
          case .failure(let error):
            self.statusMessage = error.localizedDescription
          }
        }
      }
    }
  }
  
  /// Fetches focus data for the current user (simplified version for TaskView)
  func fetchData() {
    isLoading = true
    statusMessage = "Loading..."
    
    getFocusData(user: username) { [weak self] result in
      Task { @MainActor in
        guard let self else { return }
        self.isLoading = false
        switch result {
        case .success(let data):
          self.focusData = data
          self.statusMessage = "Updated"
        case .failure(let error):
          self.statusMessage = error.localizedDescription
        }
      }
    }
  }
  
  /// Switches to a different user and fetches their data
  func switchToUser(_ newUser: String) {
    guard username != newUser else { return }
    username = newUser
    fetchData()
  }
  
  /// Refresh data (async wrapper for fetchData)
  func refreshData() async {
    fetchData()
  }
}

