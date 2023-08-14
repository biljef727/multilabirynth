//
//  ConnectFourViewModel.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 04/08/23.
//

import SwiftUI
import MultipeerConnectivity
import UIKit

class KudamanViewController:MCBrowserViewController,MCBrowserViewControllerDelegate{
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        print("risssaaaa and bend")
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
    }
    
}

class ConnnectFourViewModel: NSObject, ObservableObject {
    
    let connectFourServiceType = "multi-labirynth"
    var isConnected : Bool = false
    var isHosting : Bool = false
    
    @Published var counterPlayer : Int = 1
    @Published var startGame:Bool = false
    
    var peerId: MCPeerID
    var session: MCSession
    var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    var connectedPeers:[Int] = []
    
    override init() {
        peerId = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
       session.delegate = self
    }
    
    func host() {
        isHosting = true
        self.counterPlayer = 1
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: connectFourServiceType)
        nearbyServiceAdvertiser?.delegate = self
        nearbyServiceAdvertiser?.startAdvertisingPeer()
    }
    func cancel(){
        isHosting = false
        self.counterPlayer = 1
        session.disconnect()
        nearbyServiceAdvertiser?.stopAdvertisingPeer()
    }
    
    func join() {
        self.counterPlayer = 1
        let browser = KudamanViewController(serviceType: connectFourServiceType, session: session)
        browser.delegate = self
        
        UIApplication.shared.windows.first?.rootViewController?.present(browser , animated: true)
    }
    func disjoin(){
        isConnected = false
        self.counterPlayer -= 1
//        DispatchQueue.main.async {
//            print("enggak")
//        }
        session.disconnect()
        nearbyServiceAdvertiser?.stopAdvertisingPeer()
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
            DispatchQueue.main.async {
                self.counterPlayer += 1
                print("connected: \(self.counterPlayer)")
            }
        case .notConnected:
            print("\(peerId) state: not connected")
            DispatchQueue.main.async {
                self.counterPlayer -= 1
                print("connected: \(self.counterPlayer)")
            }
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
