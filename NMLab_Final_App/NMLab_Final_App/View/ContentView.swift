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
      HomeView()
        .tabItem {
          Label("Home", systemImage: "house")
        }
      UserDataView()
        .tabItem {
          Label("Record", systemImage: "list.bullet")
        }
      RankView()
        .tabItem {
          Label("Rank", systemImage: "chart.bar.xaxis")
        }
    }
  }

  
}

#Preview {
  ContentView()
}
