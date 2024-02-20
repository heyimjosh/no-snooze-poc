//
//  AlarmFeature.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/20/24.
//

import ComposableArchitecture

@Reducer
struct AlarmFeature {
  @ObservableState
  struct State {
    var isAlarmEnabled = false
    var alarmCount = 0
  }
  
  enum Action {
    case userTappedEnableAlarmButton
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .userTappedEnableAlarmButton:
        print("user tapped enable alarm button")
        state.isAlarmEnabled.toggle()
        return .none
      }
    }
  }
}
