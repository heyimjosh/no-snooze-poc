/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The helper class that handles the transfer of discovery tokens between peers
 and maintains the Nearby Interaction session.
 */

import NearbyInteraction
import WatchConnectivity
import os.log

enum NearbyInteractionError: Error {
  case nearbyInteractionNotSupported
  case unknownNearbyInteractionSession(errorMessage: String)
  
  var errorDescription: String? {
    switch self {
    case .unknownNearbyInteractionSession(let errorMessage):
      return errorMessage
    case .nearbyInteractionNotSupported:
      return "Your device does not support NearbyInteraction"
    }
  }
}

final actor NearbyInteractionManager: NSObject {
  
  private var distanceContinuation: AsyncThrowingStream<Measurement<UnitLength>, Error>.Continuation?
  
  private var didSendDiscoveryToken: Bool = false
  
  private var isConnected: Bool {
    return distanceContinuation != nil
  }
  
  private var niSession: NISession?
  private var niSessionDelegateVar: niSessionDelegate?
  
  override init() {
    super.init()
    
//    niSession = NISession()
//    self.niSessionDelegateVar = niSessionDelegate()
//    niSession?.delegate = self.niSessionDelegateVar
//    niSession?.delegateQueue = DispatchQueue.main
//    
//    let wcSessionDelegate = wcSessionDelegate()
//    WCSession.default.delegate = wcSessionDelegate
//    WCSession.default.activate()
    
  }
  
  func startStream() -> AsyncThrowingStream<Measurement<UnitLength>, Error> {
    
    initializeNISession()
    initializeWCSession()
    
    return AsyncThrowingStream { continuation in
      self.distanceContinuation = continuation
      self.niSession.niSessionDelegateVar?.distanceContinuation = continuation
    }
  }
  
  private func initializeNISession() {
    os_log("initializing the NISession")
    niSession = NISession()
    self.niSessionDelegateVar = niSessionDelegate()
    niSession?.delegate = self.niSessionDelegateVar
    niSession?.delegateQueue = DispatchQueue.main
  }
  
  private func initializeWCSession() {
    let wcSessionDelegate = wcSessionDelegate()
    WCSession.default.delegate = wcSessionDelegate
    WCSession.default.activate()
  }
  
  private func deinitializeNISession() {
    os_log("invalidating and deinitializing the NISession")
    niSession?.invalidate()
    niSession = nil
    didSendDiscoveryToken = false
  }
  
  private func restartNISession() {
    os_log("restarting the NISession")
    if let config = niSession?.configuration {
      niSession?.run(config)
    }
    // TODO: could there be a case where the session doesn't exist but we want to restart it?
  }
  
  /// Send the local discovery token to the paired device
  private func sendDiscoveryToken() {
    guard let token = niSession?.discoveryToken else {
      os_log("NIDiscoveryToken not available")
      return
    }
    
    guard let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
      os_log("failed to encode NIDiscoveryToken")
      return
    }
    
    do {
      try WCSession.default.updateApplicationContext([Helper.discoveryTokenKey: tokenData])
      os_log("NIDiscoveryToken \(token) sent to counterpart")
      didSendDiscoveryToken = true
    } catch let error {
      os_log("failed to send NIDiscoveryToken: \(error.localizedDescription)")
    }
  }
  
  /// When a discovery token is received, run the session
  private func didReceiveDiscoveryToken(_ token: NIDiscoveryToken) {
    
    if niSession == nil {
      initializeNISession()
    }
    if !didSendDiscoveryToken { sendDiscoveryToken() }
    
    os_log("running NISession with peer token: \(token)")
    let config = NINearbyPeerConfiguration(peerToken: token)
    niSession?.run(config)
  }
  
  final class niSessionDelegate: NSObject, NISessionDelegate {
    var distanceContinuation: AsyncThrowingStream<Measurement<UnitLength>, Error>.Continuation?
    var restartNISession: (() -> Void)?
    var deinitializeNISession: (() -> Void)?
    
    init(distanceContinuation: AsyncThrowingStream<Measurement<UnitLength>, Error>.Continuation? = nil,
         restartNISession: (() -> Void)? = nil,
         deinitializeNISession: (() -> Void)? = nil) {
      self.distanceContinuation = distanceContinuation
      self.restartNISession = restartNISession
      self.deinitializeNISession = deinitializeNISession
    }
    
    func sessionWasSuspended(_ session: NISession) {
      os_log("NISession was suspended")
      distanceContinuation = nil
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
      os_log("NISession suspension ended")
      (restartNISession ?? {})()
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
      
      guard let niError = error as? NIError else {
        os_log("Unknown error: \(error)")
        return
      }
      
      os_log("NISession did invalidate with error: \(error.localizedDescription)")
      distanceContinuation = nil
      // TODO: this doesn't nil out anything above, just nils out here
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
      if let object = nearbyObjects.first, let distance = object.distance {
        os_log("object distance: \(distance) meters")
        //self.distance = Measurement(value: Double(distance), unit: .meters)
        self.distanceContinuation?.yield(Measurement(value: Double(distance), unit: .meters))
      }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
      switch reason {
      case .peerEnded:
        os_log("the remote peer ended the connection")
        (deinitializeNISession ?? {})()
      case .timeout:
        os_log("peer connection timed out")
        (restartNISession ?? {})()
      default:
        os_log("disconnected from peer for an unknown reason")
      }
      distanceContinuation = nil
    }
  }
  
  final class wcSessionDelegate: NSObject, WCSessionDelegate {
    
    var distanceContinuation: AsyncThrowingStream<Measurement<UnitLength>, Error>.Continuation?
    var didSendDiscoveryToken: Bool = false
    var sendDiscoveryToken: (() -> Void)?
    var didReceiveDiscoveryToken: ((_ token: NIDiscoveryToken) -> Void)?
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
      guard error == nil else {
        os_log("WCSession failed to activate: \(error!.localizedDescription)")
        return
      }
      
      switch activationState {
      case .activated:
        os_log("WCSession is activated")
        if !self.didSendDiscoveryToken {
          (sendDiscoveryToken ?? {})()
        }
      case .inactive:
        os_log("WCSession is inactive")
      case .notActivated:
        os_log("WCSession is not activated")
      default:
        os_log("WCSession is in an unknown state")
      }
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
      os_log("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
      os_log("WCSession did deactivate")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
      os_log("""
              WCSession watch state did change:
                - isPaired: \(session.isPaired)
                - isWatchAppInstalled: \(session.isWatchAppInstalled)
              """)
    }
#endif
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
      if let tokenData = applicationContext[Helper.discoveryTokenKey] as? Data {
        if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
          os_log("received NIDiscoveryToken \(token) from counterpart")
          // TODO: fix this
          (didReceiveDiscoveryToken!)(token)
        } else {
          os_log("failed to decode NIDiscoveryToken")
        }
      }
    }
  }
}

