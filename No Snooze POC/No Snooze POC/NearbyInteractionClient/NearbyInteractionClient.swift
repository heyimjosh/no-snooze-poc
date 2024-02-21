import ComposableArchitecture
import Foundation
import NearbyInteraction

//@DependencyClient
struct NearbyInteractionClient {
  var distance: @Sendable () async -> AsyncThrowingStream<Measurement<UnitLength>, Error>

  init(
      distance: @Sendable @escaping () async -> AsyncThrowingStream<Measurement<UnitLength>, Error>
  ) {
      self.distance = distance
  }
}

struct NearbyInteractionState: Sendable {
  var distance: Measurement<UnitLength>
  var isConnected: Bool
}

extension NearbyInteractionClient: DependencyKey {
  static let liveValue = Self { 
    let stream = AsyncThrowingStream<Measurement<UnitLength>, Error> { continuation in
      do {
        let session = NISession()
        let delegate = try NIDelegate(
          sessionWasSuspended: { session in
            
          },
          sessionSuspensionEnded: { session in
          },
          niSessionInvalidatedWithError: { error in
            continuation.finish(throwing: error)
          },
          objectDistanceUpdated: { measurement in
            continuation.yield(measurement)
          }
        )
        
      } catch {
        continuation.finish(throwing: error)
      }
      
    }
    
    return stream
    
  }
}

private actor NIDelegate: NSObject, NISessionDelegate, Sendable {
  let sessionWasSuspended: @Sendable (NISession) -> Void
  let sessionSuspensionEnded: @Sendable (NISession) -> Void
  let niSessionInvalidatedWithError: @Sendable (Error?) -> Void
  let objectDistanceUpdated: @Sendable (Measurement<UnitLength>) -> Void
  let session: NISession

  init(
    sessionWasSuspended: @escaping @Sendable (NISession) -> Void,
    sessionSuspensionEnded: @escaping @Sendable (NISession) -> Void,
    niSessionInvalidatedWithError: @escaping @Sendable (Error?) -> Void,
    objectDistanceUpdated: @escaping @Sendable (Measurement<UnitLength>) -> Void
  ) throws {
    self.sessionWasSuspended = sessionWasSuspended
    self.sessionSuspensionEnded = sessionSuspensionEnded
    self.niSessionInvalidatedWithError = niSessionInvalidatedWithError
    self.objectDistanceUpdated = objectDistanceUpdated

    self.session = NISession()
    super.init()
    self.session.delegate = self
    session.delegateQueue = DispatchQueue.main
  }
  
  nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
    print("NISession did invalidate with error: \(error.localizedDescription)")
    self.niSessionInvalidatedWithError(error)
    
    // TODO: difference between 0 and nil'ing out?
    // NIL is probably more accurate, more "invalid"
    self.objectDistanceUpdated(Measurement(value: Double(0), unit: .meters))
  }
  
  nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    if let object = nearbyObjects.first, let distance = object.distance {
      print("object distance: \(distance) meters")
      self.objectDistanceUpdated(Measurement(value: Double(distance), unit: .meters))
    }
  }
}
