//
//  TrackerStatusFetcher.swift
//  NMLab_Final_App
//
//  Created by Cursor on 2025/12/11.
//

import Foundation

/// Error cases for tracker status requests.
enum TrackerStatusError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case decodingFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid tracker status URL."
    case .invalidResponse:
      return "Invalid tracker status response."
    case .httpError(let status, let body):
      return "HTTP \(status): \(body ?? "No body")."
    case .decodingFailed(let error):
      return "Decoding tracker status failed: \(error.localizedDescription)"
    }
  }
}

private struct TrackerStatusResponse: Decodable {
  let trackerStatus: String

  enum CodingKeys: String, CodingKey {
    case trackerStatus = "tracker_status"
  }
}

/// Fetches the latest tracker status message.
func getTrackerStatus(completion: @escaping (Result<String, Error>) -> Void) {
  let urlString = "https://icd-hw.onrender.com/tracker/status"
  guard let url = URL(string: urlString) else {
    completion(.failure(TrackerStatusError.invalidURL))
    return
  }

  URLSession.shared.dataTask(with: url) { data, response, error in
    if let error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(TrackerStatusError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let body = data.flatMap { String(data: $0, encoding: .utf8) }
      Task { @MainActor in completion(.failure(TrackerStatusError.httpError(status: httpResponse.statusCode, body: body))) }
      return
    }

    guard let data else {
      Task { @MainActor in completion(.failure(TrackerStatusError.decodingFailed(underlying: URLError(.badServerResponse)))) }
      return
    }

    let decoder = JSONDecoder()
    Task { @MainActor in
      do {
        let statusResponse = try decoder.decode(TrackerStatusResponse.self, from: data)
        completion(.success(statusResponse.trackerStatus))
      } catch {
        if let body = String(data: data, encoding: .utf8) {
          print("Raw tracker payload: \(body)")
        }
        completion(.failure(TrackerStatusError.decodingFailed(underlying: error)))
      }
    }
  }.resume()
}
