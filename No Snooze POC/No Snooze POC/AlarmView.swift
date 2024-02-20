//
//  AlarmView.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/20/24.
//

import SwiftUI
import ComposableArchitecture
//
struct AlarmView: View {
  let store: StoreOf<AlarmFeature>
  
  var body: some View {
    VStack {
      Text("\(String(store.isAlarmEnabled))")
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      HStack {
        Button("-") {
          store.send(.userTappedEnableAlarmButton)
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        
        Button("+") {
          store.send(.userTappedEnableAlarmButton)
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      }
    }
  }
}
