//
//  ContentView.swift
//  NMLab_Final_App
//
//  Created by Haruaki on 2025/11/24.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {
      Tab("Home", systemImage: "house") {
        UserDataView()
      }

      Tab("Task", systemImage: "checklist") {
        TaskView()
      }

      Tab("Rank", systemImage: "chart.bar.xaxis") {
        RankView()
      }

      Tab("Control", systemImage: "switch.2") {
        ControlView()
      }
    }
  }

  
}

#Preview {
  ContentView()
}
