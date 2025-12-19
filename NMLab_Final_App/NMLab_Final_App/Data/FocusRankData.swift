//
//  RankData.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/26.
//

import Foundation

struct FocusRankData: Codable, Identifiable {
  let username: String
  let score: Int

  var id: String { username }
}
