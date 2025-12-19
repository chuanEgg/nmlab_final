//
//  FocusStatusFetcher.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/8.
//

import Foundation

enum FocusButtonError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case decodingFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid button URL."
    case .invalidResponse: return "Invalid response object."
    case .httpError(let status, let body): return "HTTP \(status): \(body ?? "No body")."
    case .decodingFailed(let err): return "Decoding button status failed: \(err.localizedDescription)"
    }
  }
}

func getFocusStatus(completion: @escaping (Result<FocusButtonStatus, Error>) -> Void) {
  guard let url = APIConfig.url(for: "/button/status") else {
    completion(.failure(FocusButtonError.invalidURL))
    return
  }

  URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(FocusButtonError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let body = data.flatMap { String(data: $0, encoding: .utf8) }
      Task { @MainActor in completion(.failure(FocusButtonError.httpError(status: httpResponse.statusCode, body: body))) }
      return
    }

    guard let data = data else {
      Task { @MainActor in completion(.failure(FocusButtonError.decodingFailed(underlying: URLError(.badServerResponse)))) }
      return
    }

    let decoder = JSONDecoder()
    Task { @MainActor in
      do {
        let status = try decoder.decode(FocusButtonStatus.self, from: data)
        completion(.success(status))
      } catch {
        if let body = String(data: data, encoding: .utf8) {
          print("Raw button payload: \(body)")
        }
        completion(.failure(FocusButtonError.decodingFailed(underlying: error)))
      }
    }
  }.resume()
}

func toggleFocusStatus(completion: @escaping (Result<FocusButtonStatus, Error>) -> Void) {
  guard let url = APIConfig.url(for: "/button/toggle") else {
    completion(.failure(FocusButtonError.invalidURL))
    return
  }

  var request = URLRequest(url: url)
  request.httpMethod = "POST"

  URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(FocusButtonError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let body = data.flatMap { String(data: $0, encoding: .utf8) }
      Task { @MainActor in completion(.failure(FocusButtonError.httpError(status: httpResponse.statusCode, body: body))) }
      return
    }

    guard let data = data else {
      Task { @MainActor in completion(.failure(FocusButtonError.decodingFailed(underlying: URLError(.badServerResponse)))) }
      return
    }

    let decoder = JSONDecoder()
    Task { @MainActor in
      do {
        let status = try decoder.decode(FocusButtonStatus.self, from: data)
        completion(.success(status))
      } catch {
        if let body = String(data: data, encoding: .utf8) {
          print("Raw button payload: \(body)")
        }
        completion(.failure(FocusButtonError.decodingFailed(underlying: error)))
      }
    }
  }.resume()
}
