//
//  ConnectFourViewModel.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 04/08/23.
//

import SwiftUI
import MultipeerConnectivity

class ConnnectFourViewModel: NSObject, ObservableObject {
    
    let connectFourServiceType = "gt-conn4"
    var isConnected : Bool = false
    var isHosting : Bool = false
    
    @Published var counterPlayer : Int = 1
    @Published var startGame:Bool = false
    
    var peerId: MCPeerID
    var session: MCSession
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    override init() {
        peerId = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
       session.delegate = self
    }
    
    func host() {
        isHosting = true
        
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: connectFourServiceType)
        nearbyServiceAdvertiser?.delegate = self
        nearbyServiceAdvertiser?.startAdvertisingPeer()
        
        
    }
    
    func join() {
        let browser = MCBrowserViewController(serviceType: connectFourServiceType, session: session)
        browser.delegate = self
        UIApplication.shared.windows.first?.rootViewController?.present(browser , animated: true)
    }
    
    func play(){
        do {
            try session.send("play!".data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            startGame = true
        } catch {
            print(error.localizedDescription)
        }
    }

}

extension ConnnectFourViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            print("\(peerId) state: connecting")
        case .connected:
            print("\(peerId) state: connected")
            print("ada yg connect")
            DispatchQueue.main.async {
                self.counterPlayer += 1
            }
        case .notConnected:
            print("\(peerId) state: not connected")
        @unknown default:
            print("\(peerId) state: unknown")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else { return }
        if (message == "play!"){
            startGame = true
        }
    }
    
    
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension ConnnectFourViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension ConnnectFourViewModel: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
        self.isConnected = true
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        session.disconnect()
        browserViewController.dismiss(animated: true)
    }
}
