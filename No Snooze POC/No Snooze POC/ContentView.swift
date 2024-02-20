//
//  ContentView.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/20/24.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, dude!")
    }
    .padding()
    .background(.green)
  }
}

#Preview {
    ContentView()
}
