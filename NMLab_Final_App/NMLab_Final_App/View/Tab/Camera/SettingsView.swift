//
//  BaseURLSettingsView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/17.
//
import SwiftUI
import Foundation

struct SettingsView: View {
  @State private var baseURL: String = APIConfig.baseURL
  @State private var selectedAccent: AppTheme.AccentChoice = AppTheme.accentChoice
  @Environment(\.dismiss) private var dismiss
  var onSave: (() -> Void)? = nil

  var body: some View {
    Form {
      Section(header: Text("Server Base URL")) {
        TextField("For example: http://team9.local:8000", text: $baseURL)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }

      Section(header: Text("Accent Color")) {
        Picker("Accent Color", selection: $selectedAccent) {
          ForEach(AppTheme.AccentChoice.allCases) { choice in
            HStack {
              Circle()
                .fill(AppTheme.color(for: choice))
                .frame(width: 16, height: 16)
              Text(choice.displayName)
            }
            .tag(choice)
          }
        }
      }

      Section(footer: Text("Include the full scheme, for example: http://team9.local:8000")) {
        Button("Save") {
          save()
          dismiss()
        }

        Button("Reset to Default") {
          baseURL = APIConfig.defaultBaseURL
          save()
          dismiss()
        }
        .tint(.red)
      }
    }
    .navigationTitle("Settings")
  }

  private func save() {
    APIConfig.baseURL = baseURL
    AppTheme.accentChoice = selectedAccent
    onSave?()
  }
}
