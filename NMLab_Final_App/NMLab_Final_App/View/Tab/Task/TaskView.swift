//
//  TaskView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import SwiftUI

struct TaskView: View {
  @StateObject private var dataManager = TaskDataManager()
  @State private var selectedTab: TaskTab = .tasks
  @State private var hasLoadedOnce = false
  
  enum TaskTab {
    case tasks
    case achievements
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Tab selector
        Picker("View", selection: $selectedTab) {
          Text("Tasks").tag(TaskTab.tasks)
          Text("Achievements").tag(TaskTab.achievements)
        }
        .pickerStyle(.segmented)
        .padding()
        
        // Content
        if dataManager.isLoading {
          ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let focusData = dataManager.focusData {
          if selectedTab == .tasks {
            tasksView(focusData: focusData)
          } else {
            achievementsView(focusData: focusData)
          }
        } else {
          VStack(spacing: 16) {
            Image(systemName: "tray")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)
            Text("No data available")
              .foregroundStyle(.secondary)
            Button("Refresh") {
              dataManager.fetchData()
            }
            .buttonStyle(.borderedProminent)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .navigationTitle("Tasks & Achievements")
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
      .refreshable {
        await dataManager.refreshData()
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
    }
  }
  
  @ViewBuilder
  private func tasksView(focusData: FocusData) -> some View {
    let tasks = generateTasks(from: focusData)
    let tasksByCategory = Dictionary(grouping: tasks) { $0.category }
    
    ScrollView {
      LazyVStack(spacing: 16) {
        // Summary card
        summaryCard(tasks: tasks)
          .padding(.horizontal)
          .padding(.top, 8)
        
        // Tasks by category
        ForEach(TaskCategory.allCases, id: \.self) { category in
          if let categoryTasks = tasksByCategory[category], !categoryTasks.isEmpty {
            Section {
              ForEach(categoryTasks) { task in
                TaskRowView(task: task)
              }
            } header: {
              HStack {
                Image(systemName: category.icon)
                  .foregroundStyle(colorForCategory(category))
                Text(category.rawValue)
                  .font(.headline)
                  .foregroundStyle(.primary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, 8)
            }
          }
        }
      }
      .padding(.bottom)
    }
  }
  
  @ViewBuilder
  private func achievementsView(focusData: FocusData) -> some View {
    let achievements = generateAchievements(from: focusData)
    let unlockedCount = achievements.filter { $0.isUnlocked }.count
    let totalCount = achievements.count
    
    ScrollView {
      LazyVStack(spacing: 16) {
        // Summary card
        achievementSummaryCard(unlocked: unlockedCount, total: totalCount)
          .padding(.horizontal)
          .padding(.top, 8)
        
        // Achievements by rarity
        ForEach(AchievementRarity.allCases.reversed(), id: \.self) { rarity in
          let rarityAchievements = achievements.filter { $0.rarity == rarity }
          if !rarityAchievements.isEmpty {
            Section {
              LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
              ], spacing: 12) {
                ForEach(rarityAchievements) { achievement in
                  AchievementCardView(achievement: achievement)
                }
              }
            } header: {
              HStack {
                Text(rarity.rawValue)
                  .font(.headline)
                  .foregroundStyle(colorForRarity(rarity))
                Spacer()
                Text("\(rarityAchievements.filter { $0.isUnlocked }.count)/\(rarityAchievements.count)")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal)
              .padding(.top, 8)
            }
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom)
    }
  }
  
  @ViewBuilder
  private func summaryCard(tasks: [FocusTask]) -> some View {
    let completedCount = tasks.filter { $0.isCompleted }.count
    let totalCount = tasks.count
    let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
          .font(.title2)
        VStack(alignment: .leading, spacing: 4) {
          Text("Tasks Progress")
            .font(.headline)
          Text("\(completedCount) of \(totalCount) completed")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
          RoundedRectangle(cornerRadius: 8)
            .fill(.green)
            .frame(width: geometry.size.width * progress)
        }
      }
      .frame(height: 8)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    )
  }
  
  @ViewBuilder
  private func achievementSummaryCard(unlocked: Int, total: Int) -> some View {
    let progress = total > 0 ? Double(unlocked) / Double(total) : 0.0
    
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "trophy.fill")
          .foregroundStyle(.yellow)
          .font(.title2)
        VStack(alignment: .leading, spacing: 4) {
          Text("Achievements")
            .font(.headline)
          Text("\(unlocked) of \(total) unlocked")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
          RoundedRectangle(cornerRadius: 8)
            .fill(.yellow)
            .frame(width: geometry.size.width * progress)
        }
      }
      .frame(height: 8)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    )
  }
}

#Preview {
  TaskView()
}
