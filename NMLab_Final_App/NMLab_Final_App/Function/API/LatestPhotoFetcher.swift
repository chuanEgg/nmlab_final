//
//  LatestPhotoFetcher.swift
//  NMLab_Final_App
//
//  Created by ChatGPT on 2025/12/10.
//

import Foundation
import UIKit

enum LatestPhotoError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpError(status: Int, body: String?)
  case noData
  case invalidImage

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid latest photo URL."
    case .invalidResponse:
      return "Invalid response object."
    case .httpError(let status, let body):
      return "HTTP \(status): \(body ?? "No body")."
    case .noData:
      return "No photo returned by server."
    case .invalidImage:
      return "Received data is not a valid image."
    }
  }
}

func fetchLatestPhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
  guard let url = APIConfig.url(for: "/latest_photo") else {
    completion(.failure(LatestPhotoError.invalidURL))
    return
  }

  var request = URLRequest(url: url)
  request.httpMethod = "GET"

  URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
      Task { @MainActor in completion(.failure(error)) }
      return
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Task { @MainActor in completion(.failure(LatestPhotoError.invalidResponse)) }
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let body = data.flatMap { String(data: $0, encoding: .utf8) }
      Task { @MainActor in
        completion(.failure(LatestPhotoError.httpError(status: httpResponse.statusCode, body: body)))
      }
      return
    }

    guard let data else {
      Task { @MainActor in completion(.failure(LatestPhotoError.noData)) }
      return
    }

    guard let image = UIImage(data: data) else {
      Task { @MainActor in completion(.failure(LatestPhotoError.invalidImage)) }
      return
    }

    Task { @MainActor in completion(.success(image)) }
  }.resume()
}

