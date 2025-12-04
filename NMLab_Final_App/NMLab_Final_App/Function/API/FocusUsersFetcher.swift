//
//  FocusUsersFetcher.swift
//  NMLab_Final_App
//
//  Created by ChatGPT on 2025/11/26.
//

import Foundation

enum FocusUsersError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case decodingFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid users URL."
    case .invalidResponse:
      return "Invalid response object."
    case .httpError(let status, let body):
      return "HTTP \(status): \(body ?? "No body")."
    case .decodingFailed(let error):
      return "Decoding users failed: \(error.localizedDescription)"
    }
  }
}

func getFocusUsers(completion: @escaping (Result<[String], Error>) -> Void) {
  let baseURL = "https://icd-hw.onrender.com/users"
  guard let url = URL(string: baseURL) else {
    completion(.failure(FocusUsersError.invalidURL))
    return
  }

  URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(FocusUsersError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }
      Task {
        @MainActor in completion(.failure(FocusUsersError.httpError(status: httpResponse.statusCode, body: bodyString)))
      }
      return
    }

    guard let data else {
      Task { @MainActor in completion(.success([])) }
      return
    }

    do {
      let response = try JSONDecoder().decode(FocusUsersResponse.self, from: data)
      Task { @MainActor in completion(.success(response.usernames)) }
    } catch {
      if let bodyString = String(data: data, encoding: .utf8) {
        print("Raw users payload: \(bodyString)")
      }
      Task { @MainActor in completion(.failure(FocusUsersError.decodingFailed(underlying: error))) }
    }
  }.resume()
}
