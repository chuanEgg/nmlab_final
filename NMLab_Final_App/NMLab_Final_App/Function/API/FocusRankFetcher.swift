//
//  FocusRank.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import Foundation

enum FocusRankError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case decodingFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid rank URL."
    case .invalidResponse:
      return "Invalid rank response."
    case .httpError(let status, let body):
      return "HTTP \(status): \(body ?? "No body")."
    case .decodingFailed(let error):
      return "Decoding rank data failed: \(error.localizedDescription)"
    }
  }
}

func getFocusRank(completion: @escaping (Result<[FocusRankData], Error>) -> Void) {
  guard let url = APIConfig.url(for: "/rank") else {
    completion(.failure(FocusRankError.invalidURL))
    return
  }

  URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(FocusRankError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let bodyString = data.flatMap { String(data: $0, encoding: .utf8) }
      Task {
        @MainActor in completion(.failure(FocusRankError.httpError(status: httpResponse.statusCode, body: bodyString)))
      }
      return
    }

    guard let data else {
      Task { @MainActor in completion(.success([])) }
      return
    }

    do {
      let ranks = try JSONDecoder().decode([FocusRankData].self, from: data)
      Task { @MainActor in completion(.success(ranks)) }
    } catch {
      if let bodyString = String(data: data, encoding: .utf8) {
        print("Raw rank payload: \(bodyString)")
      }
      Task { @MainActor in completion(.failure(FocusRankError.decodingFailed(underlying: error))) }
    }
  }.resume()
}
