//
//  InfoBadge.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/5.
//

import Foundation
import SwiftUI

// MARK: - Badge Helpers

func infoBadge(dateText: String, valueTitle: String, valueText: String) -> some View {
  VStack(alignment: .leading, spacing: 2) {
    Text(valueTitle)
      .font(.caption.weight(.medium))
      .foregroundStyle(.secondary)
    Text(valueText)
      .font(.title.weight(.semibold))
      .foregroundStyle(.primary)
    Text(dateText)
      .font(.callout.weight(.semibold))
      .foregroundStyle(.secondary)
  }
}
