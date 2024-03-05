//
//  ContentView.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/20/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature {
  
  @ObservableState
  struct State: Equatable {
    var dummyVar: String = "dummy"
    var distance: Double = 0.0
  }
  
  enum Action {
    case task
    case distanceYielded(distance: Double)
    case errorYielded(error: NearbyInteractionError)
  }
  
  @Dependency(\.nearbyInteractionClient) var nearbyInteractionClient
  
  var body: some ReducerOf<Self> {
    
    Reduce { state, action in
      
      switch action {
        
      case .task:
        return .run { send in
          do {
            for try await emittedDistance in await nearbyInteractionClient.startNearbyInteractionClient() {
              let distanceInMeters = emittedDistance.converted(to: .meters).value
              await send(.distanceYielded(distance: distanceInMeters))
            }
          } catch let error as NearbyInteractionError {
            await send(.errorYielded(error: error))
          }
        }
      
        
      case .distanceYielded(distance: let distance):
        print("Distance yielded: \(distance)")
        state.distance = distance
        return .none
      case .errorYielded(error: let error):
        print("Error yielded: \(error.localizedDescription)")
        return .none
      }
      
    }
  }
  
}

struct ContentView: View {
  
  let store: StoreOf<AppFeature>
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, \(store.distance)")
    }
    .padding()
    .background(.green)
    .task { await store.send(.task).finish() }
    
  }
}

//#Preview {
//    ContentView()
//}
