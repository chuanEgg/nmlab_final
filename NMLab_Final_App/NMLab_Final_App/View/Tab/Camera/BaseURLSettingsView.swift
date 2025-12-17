//
//  BaseURLSettingsView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/17.
//
import SwiftUI
import Foundation

struct BaseURLSettingsView: View {
  @State private var baseURL: String = APIConfig.baseURL
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
    .navigationTitle("API Settings")
  }

  private func save() {
    APIConfig.baseURL = baseURL
    onSave?()
  }
}
