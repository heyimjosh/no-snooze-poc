//
//  NearbyClient.swift
//  No Snooze POC
//
//  Created by Josh Davis on 2/27/24.
//

import Foundation
import ComposableArchitecture
import NearbyInteraction

@DependencyClient
struct NearbyInteractionClient {
  var startNearbyInteractionClient:
  @Sendable () async -> AsyncThrowingStream<
    Measurement<UnitLength>, Error
  > = { .finished() }
  
  var finishTask: @Sendable () async -> Void
}

extension NearbyInteractionClient: DependencyKey {
  static var liveValue: Self {
    
    /// NearbyInteraction is only supported on devices with a U1 chip. Let's decide if this user can do it
    var isSupported: Bool
    if #available(iOS 16.0, watchOS 9.0, *) {
      isSupported = NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
    } else {
      isSupported = NISession.isSupported
    }
    
    /// If NearbyInteraction is supported, initialize the Manager and start the client
    if isSupported {
      let niManager = NearbyInteractionManager()
      return Self(
        startNearbyInteractionClient: {
          return await niManager.startStream()
        },
        finishTask: {
          //await speech.finishTask()
          print("Finished")
        }
      )
    } 
    
    /// If NearbyInteraction is not supported, immediately thow that error and eventually alert the user
    else {
      return Self(
        startNearbyInteractionClient: {
          return AsyncThrowingStream { continuation in
            continuation.finish(throwing: NearbyInteractionError.nearbyInteractionNotSupported)
          }
        },
        /// Don't need finishTask because the AsyncStream will finish and throw immediately
        finishTask: {})
    }
  }
}
