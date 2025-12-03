//
//  FocusDetailChartView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/12/3.
//

import Charts
import SwiftUI

struct FocusDetailChartView: View {
  @State private var selectedTrendPoint: FocusTrendPoint?
  let focusData: FocusData

  var body: some View {
    if trendDataPoints.isEmpty {
      Text("Not enough recent play-time data.")
        .foregroundStyle(.secondary)
    } else {
      VStack(alignment: .leading) {
        chartInfoBadge
        Chart {
        ForEach(trendDataPoints) { point in
          LineMark(
            x: .value("Day", point.date),
            y: .value("Minutes", point.durationMinutes)
          )
          .foregroundStyle(.accent)
          .interpolationMethod(.catmullRom)

          // Outer ring
          PointMark(
            x: .value("Day", point.date),
            y: .value("Minutes", point.durationMinutes)
          )
          .symbolSize(120)
          .foregroundStyle(.accent)

          // Inner cutout to achieve a ring shape
          PointMark(
            x: .value("Day", point.date),
            y: .value("Minutes", point.durationMinutes)
          )
          .symbolSize(selectedTrendPoint?.id == point.id ? 60 : 40)
          .foregroundStyle(Color(.systemBackground))
          .opacity(0.95)
        }

        if let selectedTrendPoint {
          RuleMark(x: .value("Day", selectedTrendPoint.date))
            .foregroundStyle(.accent.opacity(0.6))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

          PointMark(
            x: .value("Day", selectedTrendPoint.date),
            y: .value("Minutes", selectedTrendPoint.durationMinutes)
          )
          .symbolSize(160)
          .foregroundStyle(.accent)
        }
        }
        .frame(height: 220)
        .chartXAxis {
          AxisMarks(values: .stride(by: .day)) { value in
            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
          }
        }
        .chartYAxis {
          AxisMarks { value in
            AxisGridLine()
            AxisTick()
            if let minutes = value.as(Double.self) {
              let duration = TimeInterval(minutes * 60)
              AxisValueLabel {
                Text(formatDuration(duration))
              }
            }
          }
        }
        .chartOverlay { proxy in
          GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
              .gesture(
                DragGesture(minimumDistance: 0)
                  .onChanged { value in
                    updateSelection(
                      with: value.location,
                      proxy: proxy,
                      geometry: geo
                    )
                  }
                  .onEnded { _ in
                    selectedTrendPoint = nil
                  }
              )
          }
        }
      }

      if let totalText = trendSummaryText {
        HStack(spacing: 2) {
          Text("Last \(trendDataPoints.count) days:")
            .font(.footnote.weight(.semibold))
          Spacer()
          Text("\(totalText) in total")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
          Capsule()
            .fill(Color(.systemBackground))
        )
        .overlay(
          Capsule()
            .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
      }
    }
  }

  private var trendDataPoints: [FocusTrendPoint] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let samples = focusData.recentPlayTimes(limit: 7)
    return samples.enumerated().compactMap { index, seconds in
      let offset = -(samples.count - index - 1)
      guard let date = calendar.date(byAdding: .day, value: offset, to: today)
      else { return nil }
      return FocusTrendPoint(date: date, durationSeconds: seconds)
    }
  }

  private var trendSummaryText: String? {
    guard !trendDataPoints.isEmpty else { return nil }
    let totalSeconds = trendDataPoints.reduce(0) { $0 + $1.durationSeconds }
    return formatDuration(TimeInterval(totalSeconds))
  }

  private func nearestTrendPoint(to date: Date) -> FocusTrendPoint? {
    guard !trendDataPoints.isEmpty else { return nil }
    return trendDataPoints.min {
      abs($0.date.timeIntervalSince(date))
        < abs($1.date.timeIntervalSince(date))
    }
  }

  private func updateSelection(
    with location: CGPoint,
    proxy: ChartProxy,
    geometry: GeometryProxy
  ) {
    guard let plotFrame = proxy.plotFrame else {
      selectedTrendPoint = nil
      return
    }
    let frame = geometry[plotFrame]
    let relativeLocation = CGPoint(
      x: location.x - frame.origin.x,
      y: location.y - frame.origin.y
    )
    guard relativeLocation.x >= 0, relativeLocation.y >= 0,
      relativeLocation.x <= frame.size.width,
      relativeLocation.y <= frame.size.height,
      let date: Date = proxy.value(atX: relativeLocation.x)
    else {
      selectedTrendPoint = nil
      return
    }
    selectedTrendPoint = nearestTrendPoint(to: date)
  }

  // MARK: - Overlays

  private var chartInfoBadge: some View {
    Group {
      if let selectedTrendPoint {
        infoBadge(
          dateText: trendAnnotationFormatter.string(from: selectedTrendPoint.date),
          valueTitle: "Focus Time",
          valueText: formatDuration(TimeInterval(selectedTrendPoint.durationSeconds))
        )
      } else if let averageText = averagePlaytimeText {
        infoBadge(
          dateText: trendDateRangeText ?? "—",
          valueTitle: "Average",
          valueText: averageText
        )
      }
    }
  }

  private var averagePlaytimeText: String? {
    guard !trendDataPoints.isEmpty else { return nil }
    let totalSeconds = trendDataPoints.reduce(0) { $0 + $1.durationSeconds }
    let averageSeconds = totalSeconds / trendDataPoints.count
    return formatDuration(TimeInterval(averageSeconds))
  }

  private var trendDateRangeText: String? {
    guard let firstDate = trendDataPoints.first?.date,
          let lastDate = trendDataPoints.last?.date else { return nil }
    if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
      return trendAnnotationFormatter.string(from: firstDate)
    }

    return "\(trendAnnotationFormatter.string(from: firstDate)) – \(trendAnnotationFormatter.string(from: lastDate))"
  }
}

// MARK: - Badge Helpers

private func infoBadge(dateText: String, valueTitle: String, valueText: String) -> some View {
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
//  .padding(.vertical, 10)
//  .padding(.horizontal, 14)
  .background(
    Capsule(style: .continuous)
      .fill(Color(.systemBackground))
  )
  .overlay(
    Capsule(style: .continuous)
      .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
  )
}

private let trendAnnotationFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMM d"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter
}()

#Preview {
  UserDataView()
}
