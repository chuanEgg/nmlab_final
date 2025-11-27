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
  let playTime: Int
  let score: Int
  let sessions: [FocusSession]

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case username
    case level
    case playTime = "play_time"
    case score
    case sessions
  }

  init(id: String, username: String, level: Int, playTime: Int, score: Int, sessions: [FocusSession]) {
    self.id = id
    self.username = username
    self.level = level
    self.playTime = playTime
    self.score = score
    self.sessions = sessions
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    username = try container.decode(String.self, forKey: .username)
    level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
    playTime = try container.decodeIfPresent(Int.self, forKey: .playTime) ?? 0
    score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
    sessions = try container.decodeIfPresent([FocusSession].self, forKey: .sessions) ?? []
  }
}

struct FocusSession: Codable, Identifiable {
  let id = UUID()
  let startTime: TimeInterval
  let endTime: TimeInterval

  enum CodingKeys: String, CodingKey {
    case startTime = "start_time"
    case endTime = "end_time"
  }

  private static let sessionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()

  init(startTime: TimeInterval, endTime: TimeInterval) {
    self.startTime = startTime
    self.endTime = endTime
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    startTime = try FocusSession.decodeTimeInterval(for: .startTime, in: container)
    endTime = try FocusSession.decodeTimeInterval(for: .endTime, in: container)
  }

  private static func decodeTimeInterval(for key: CodingKeys, in container: KeyedDecodingContainer<CodingKeys>) throws -> TimeInterval {
    let rawValue = try container.decode(String.self, forKey: key)
    guard let date = FocusSession.sessionDateFormatter.date(from: rawValue) else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Invalid date format: \(rawValue)"
      )
    }
    return date.timeIntervalSince1970
  }

  var duration: TimeInterval {
    endTime - startTime
  }

  var startDate: Date {
    Date(timeIntervalSince1970: startTime)
  }

  var endDate: Date {
    Date(timeIntervalSince1970: endTime)
  }
}
