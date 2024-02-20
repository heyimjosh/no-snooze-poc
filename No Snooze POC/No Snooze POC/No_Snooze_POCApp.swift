//
//  No_Snooze_POCApp.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/20/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct No_Snooze_POCApp: App {
  static let store = Store(initialState: AlarmFeature.State()) {
    AlarmFeature()
      ._printChanges()
  }
  
  var body: some Scene {
    WindowGroup {
      AlarmView(store: No_Snooze_POCApp.store)
    }
  }
}
