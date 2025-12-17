//
//  FocusDataDecoder.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import Foundation

enum FocusDataError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case noData
  case userNotFound(username: String)
  case decodingFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid focus data URL."
    case .invalidResponse:
      return "Invalid response object."
    case .httpError(let status, let body):
      return "HTTP \(status): \(body ?? "No body")."
    case .noData:
      return "No data returned by server."
    case .userNotFound(let username):
      return "User \(username) not found in response."
    case .decodingFailed(let underlying):
      return "Decoding FocusData failed: \(underlying.localizedDescription)"
    }
  }
}

func getFocusData(user: String, completion: @escaping (Result<FocusData, Error>) -> Void) {
  guard let url = APIConfig.url(for: "/status/\(user)") else {
    completion(.failure(FocusDataError.invalidURL))
    return
  }

  URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(FocusDataError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }
      Task {
        @MainActor in completion(.failure(FocusDataError.httpError(status: httpResponse.statusCode, body: bodyString)))
      }
      return
    }

    guard let data = data else {
      Task { @MainActor in completion(.failure(FocusDataError.noData)) }
      return
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    Task { @MainActor in
      do {
        if let focusData = try? decoder.decode(FocusData.self, from: data) {
          completion(.success(focusData))
          return
        }

        let focusList = try decoder.decode([FocusData].self, from: data)
        if let matched = focusList.first(where: { $0.username.caseInsensitiveCompare(user) == .orderedSame }) {
          completion(.success(matched))
        } else {
          completion(.failure(FocusDataError.userNotFound(username: user)))
        }
      } catch {
        if let bodyString = String(data: data, encoding: .utf8) {
          print("Raw payload: \(bodyString)")
        }
        completion(.failure(FocusDataError.decodingFailed(underlying: error)))
      }
    }
  }.resume()
}
