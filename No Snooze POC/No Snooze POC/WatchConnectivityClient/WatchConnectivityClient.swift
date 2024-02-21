//import ComposableArchitecture
//import Foundation
//import WatchConnectivity
//
//struct WatchConnectivityClient {
//  enum Action  {
//    case didReceiveMessage([String: Any])
//  }
//  
//  var sendMessage: ([String: Any]) async throws -> [String: Any]?
//  var didRecieveMessage: () async -> [String: Any]
//}
//
//extension WatchConnectivityClient: DependencyKey {
//  static var liveValue: Self = {
//    final actor WCSessionActor: GlobalActor {
//      private var session: WCSession
//      static let shared = WCSessionActor()
//      let delegate = Delegate()
//      
//      private init() {
//        self.session = WCSession.default
//        self.session.delegate = delegate
//        session.activate()
//      }
//      
//      func sendMessage(_ message: [String: Any]) async throws -> [String: Any] {
//        return try await withCheckedThrowingContinuation({ continuation in
//          self.session.sendMessage(message, replyHandler: { reply in
//            continuation.resume(returning: reply)
//          }, errorHandler: { error in
//            continuation.resume(throwing: error)
//          })
//        })
//      }
//      
//      func didReceiveMessage() async -> [String: Any] {
//        await withCheckedContinuation({ continuation in
//          if delegate.continuation == nil {
//            delegate.continuation = continuation
//          }
//          
//        })
//      }
//      
//      final class Delegate: NSObject, WCSessionDelegate {
//        func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//            guard error == nil else {
//                print("WCSession failed to activate: \(error!.localizedDescription)")
//                return
//            }
//            
//            switch activationState {
//            case .activated:
//                print("WCSession is activated")
////                if !didSendDiscoveryToken {
////                    sendDiscoveryToken()
////                }
//            case .inactive:
//                print("WCSession is inactive")
//            case .notActivated:
//                print("WCSession is not activated")
//            default:
//                print("WCSession is in an unknown state")
//            }
//        }
//
//        #if os(iOS)
//        func sessionDidBecomeInactive(_ session: WCSession) {
//            print("WCSession did become inactive")
//        }
//
//        func sessionDidDeactivate(_ session: WCSession) {
//            print("WCSession did deactivate")
//        }
//        
//        func sessionWatchStateDidChange(_ session: WCSession) {
//            print("""
//                WCSession watch state did change:
//                  - isPaired: \(session.isPaired)
//                  - isWatchAppInstalled: \(session.isWatchAppInstalled)
//                """)
//        }
//        #endif
//        
//        func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
//            if let tokenData = applicationContext[Helper.discoveryTokenKey] as? Data {
//                if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) {
//                    os_log("received NIDiscoveryToken \(token) from counterpart")
//                    self.didReceiveDiscoveryToken(token)
//                } else {
//                    os_log("failed to decode NIDiscoveryToken")
//                }
//            }
//        }
//      }
//    }
//    
//    return Self(
//      sendMessage: { message in
//        try await WCSessionActor.shared.sendMessage(message)
//      }, didRecieveMessage: {
//        await WCSessionActor.shared.didReceiveMessage()
//      }
//    )
//  }()
//}
//
