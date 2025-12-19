//
//  FocusStatus.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/8.
//

import Foundation

struct FocusButtonStatus: Codable {
  let buttonStatus: Int

  enum CodingKeys: String, CodingKey {
    case buttonStatus = "button_status"
  }
}
