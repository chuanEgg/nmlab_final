//
//  UserDataFormat.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import Foundation

struct FocusData: Codable, Identifiable {
  let id: String
  let username: String
  let level: Int
  /// Raw play-time slices (in seconds) as delivered by the backend.
  let playTimes: [Int]
  let score: Int
  /// Per-session score values aligned with `sessions` by index.
  let sessionScores: [Int]
  let sessions: [FocusSession]

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case username
    case level
    case playTimes = "play_time"
    case score
    case sessionScores = "scores"
    case sessions
  }

  init(
    id: String,
    username: String,
    level: Int,
    playTimes: [Int],
    score: Int,
    sessionScores: [Int],
    sessions: [FocusSession]
  ) {
    self.id = id
    self.username = username
    self.level = level
    self.playTimes = playTimes
    self.score = score
    self.sessionScores = sessionScores
    self.sessions = sessions
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    username = try container.decode(String.self, forKey: .username)
    level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
    playTimes = try container.decodeIfPresent([Int].self, forKey: .playTimes) ?? []
    score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
    sessionScores = try container.decodeIfPresent([Int].self, forKey: .sessionScores) ?? []
    sessions = try container.decodeIfPresent([FocusSession].self, forKey: .sessions) ?? []
  }

  /// Aggregated play time (seconds) derived from `playTimes`.
  var totalPlayTimeSeconds: Int {
    playTimes.reduce(0, +)
  }

  /// Returns the most recent `limit` play-time entries (oldest to newest).
  func recentPlayTimes(limit: Int) -> [Int] {
    guard limit > 0 else { return [] }
    return Array(playTimes.suffix(limit))
  }
}

struct FocusSession: Codable, Identifiable {
  let id = UUID()
  let startTime: TimeInterval
  let endTime: TimeInterval
  let isOngoing: Bool

  enum CodingKeys: String, CodingKey {
    case startTime = "start_time"
    case endTime = "end_time"
  }

  private static let sessionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    // Backend timestamps are in UTC+8 without explicit offset.
    formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
    return formatter
  }()

  init(startTime: TimeInterval, endTime: TimeInterval) {
    self.startTime = startTime
    self.endTime = endTime
    self.isOngoing = false
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    startTime = try FocusSession.decodeTimeInterval(for: .startTime, in: container, allowNilAsNow: false)

    // If end_time is null, mark as ongoing and use current time for a rolling duration.
    let endIsNil = (try? container.decodeNil(forKey: .endTime)) == true
    isOngoing = endIsNil
    if endIsNil {
      endTime = Date().timeIntervalSince1970
    } else {
      endTime = try FocusSession.decodeTimeInterval(for: .endTime, in: container, allowNilAsNow: false)
    }
  }

  /// Decodes a date as a `TimeInterval` from either a formatted string or (optionally) `null`.
  /// - Parameters:
  ///   - key: Coding key to decode.
  ///   - container: Container to decode from.
  ///   - allowNilAsNow: If `true` and the value is `null`, returns the current time instead of failing.
  private static func decodeTimeInterval(
    for key: CodingKeys,
    in container: KeyedDecodingContainer<CodingKeys>,
    allowNilAsNow: Bool
  ) throws -> TimeInterval {
    // Handle explicit null (e.g. ongoing session with no end_time yet)
    if allowNilAsNow, (try? container.decodeNil(forKey: key)) == true {
      return Date().timeIntervalSince1970
    }

    // Primary path: string date like "2025-11-24T15:00:00"
    if let rawValue = try? container.decode(String.self, forKey: key),
       let date = FocusSession.sessionDateFormatter.date(from: rawValue) {
      return date.timeIntervalSince1970
    }

    throw DecodingError.dataCorruptedError(
      forKey: key,
      in: container,
      debugDescription: "Invalid or missing date value for key \(key)"
    )
  }

  var duration: TimeInterval {
    if isOngoing {
      return Date().timeIntervalSince1970 - startTime
    }
    return endTime - startTime
  }

  var startDate: Date {
    Date(timeIntervalSince1970: startTime)
  }

  var endDate: Date {
    Date(timeIntervalSince1970: endTime)
  }
}
