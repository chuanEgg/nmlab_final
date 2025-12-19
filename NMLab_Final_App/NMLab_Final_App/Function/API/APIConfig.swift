//
//  APIConfig.swift
//  NMLab_Final_App
//
//  Created by Cursor on 2025/12/17.
//

import Foundation

/// Global configuration for API base URL used by all fetchers.
enum APIConfig {
  private static let baseURLKey = "APIBaseURL"

  /// Default base URL used when the user has not customized it yet.
  static let defaultBaseURL: String = "http://team9.local:8000"

  /// The current base URL. This value is persisted in `UserDefaults`.
  static var baseURL: String {
    get {
      if let stored = UserDefaults.standard.string(forKey: baseURLKey),
         !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return stored
      }
      return defaultBaseURL
    }
    set {
      let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
      UserDefaults.standard.set(trimmed, forKey: baseURLKey)
    }
  }

  /// Builds a URL by combining the current baseURL with the given path.
  /// - Parameter path: Path starting with or without `/`, e.g. `"status"` or `"/status"`.
  /// - Returns: A URL composed from baseURL and the provided path.
  static func url(for path: String) -> URL? {
    var base = baseURL
    if base.hasSuffix("/") {
      base.removeLast()
    }

    var normalizedPath = path
    if !normalizedPath.hasPrefix("/") {
      normalizedPath = "/" + normalizedPath
    }

    return URL(string: base + normalizedPath)
  }
}

