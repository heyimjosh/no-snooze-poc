import ComposableArchitecture
import Foundation
import NearbyInteraction

@DependencyClient
public struct NearbyInteractionClient {
  public var endNearbyInteractionSession: () async -> Void
  public var objectDistanceStream: () throws -> AsyncStream<Measurement<UnitLength>>
  
  public init(endNearbyInteractionSession: @escaping () -> Void,
              objectDistanceStream: @escaping () -> AsyncStream<Measurement<UnitLength>>) {
    self.endNearbyInteractionSession = endNearbyInteractionSession
    self.objectDistanceStream = objectDistanceStream
  }
}

extension NearbyInteractionClient: DependencyKey {
  
  public static var liveValue: NearbyInteractionClient {
    
    let delegate = NISessionDelegateImpl()
    let actor = NearbyInteractionSessionActor(delegate: delegate)
    
    let endNearbyInteractionSession: () async -> Void = {
      // Logic to start NISession
      await actor.deinitializeNISession()
    }
    
    let objectDistanceStream: () -> AsyncStream<Measurement<UnitLength>> = {
      AsyncStream<Measurement<UnitLength>>(Measurement<UnitLength>.self, bufferingPolicy: .bufferingNewest(1)) { continuation in
        
        // ??
        
        continuation.onTermination = { _ in
          await actor.deinitializeNISession()
        }
      }
    }
    
    return Self(endNearbyInteractionSession: endNearbyInteractionSession, objectDistanceStream: objectDistanceStream)
  }
  
  private actor NearbyInteractionSessionActor {
    var session: NISession?
    
    init(delegate: NISessionDelegateImpl) {
      self.session = NISession()
      session?.delegate = delegate
      //session?.delegateQueue = DispatchQueue.main
    }
    
    func deinitializeNISession() {
      print("invalidating and deinitializing the NISession")
      session?.invalidate()
      session = nil
    }
  }
}



private class NISessionDelegateImpl: NSObject, NISessionDelegate {
  var continuation: AsyncStream<Measurement<UnitLength>>.Continuation?
  var startSession: (() -> Void)?
  
  override init() {
  }
  
  func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    if let continuation = continuation, let object = nearbyObjects.first, let distance = object.distance {
      print("object distance: \(distance) meters")
      continuation.yield(Measurement(value: Double(distance), unit: .meters))
    }
  }
  
  func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
      switch reason {
      case .peerEnded:
          print("the remote peer ended the connection")
          //deinitializeNISession()
      case .timeout:
          print("peer connection timed out")
          //restartNISession()
      default:
          print("disconnected from peer for an unknown reason")
      }
      //distance = nil
    // yield a nil out and terminate the stream?
  }
  
  func start() {
    startSession?()
  }
}

/*
 struct NearbyInteractionClient {
 var distanceStream: @Sendable () async throws -> AsyncThrowingStream<Measurement<UnitLength>, Error>
 
 init(
 distanceStream: @Sendable @escaping () async -> AsyncThrowingStream<Measurement<UnitLength>, Error>
 ) {
 self.distanceStream = distanceStream
 }
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
 */
