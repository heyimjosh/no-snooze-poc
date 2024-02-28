//
//  NearbyClient.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/27/24.
//

import Foundation
import ComposableArchitecture

@DependencyClient
struct NearbyClient {
  var startNearbyClient:
    @Sendable () async -> AsyncThrowingStream<
      Measurement<UnitLength>, Error
    > = { .finished() }
  
  var finishTask: @Sendable () async -> Void
}

extension NearbyClient: DependencyKey {
  static var liveValue: Self {
    let nearbyInteractionManager = NearbyInteractionManager()
    return Self(
      startNearbyClient: {
//        let request = UncheckedSendable(request)
//        return await speech.startTask(request: request)
        return await nearbyInteractionManager.startTask()
        
      },
      finishTask: {
        //await speech.finishTask()
        print("Finished")
      }
    )
  }
}
