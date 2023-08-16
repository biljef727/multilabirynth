//
//  ContentStoryBoard.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 14/08/23.
//

import Foundation
import ARKit
import RealityKit
import MultipeerSession

class ContentStoryBoard: NSObject, ObservableObject, ARCoachingOverlayViewDelegate{
    var multipeerSession: MultipeerSession?
    var sessionIDObservation:NSKeyValueObservation?
    
    @objc var arView: ARView
    init(multipeerSession: MultipeerSession? = nil, sessionIDObservation: NSKeyValueObservation? = nil, arView: ARView) {
        self.multipeerSession = multipeerSession
        self.sessionIDObservation = sessionIDObservation
        self.arView = arView
    }
    func setupMultipeerSession(){
        sessionIDObservation = observe(\.arView.session.identifier, options: [.new]){
            object , change in print("SessionID Changed To: \(change.newValue!)")
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers:multipeerSession.connectedPeers)
        }
        multipeerSession = MultipeerSession(serviceName: "multi-labir", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
    }
}

extension ContentStoryBoard {
    private func sendARSessionIDTo(peers: [PeerID]){
        guard let multipeerSession = multipeerSession else { return }
        let idString = self.arView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8){
            multipeerSession.sendToPeers(commandData,reliably:true,peers:peers)
        }
    }
    func receivedData(_ data: Data, from peer: PeerID){
        guard let multipeerSession = multipeerSession else { return }
        
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data){
            arView.session.update(with:collaborationData)
            return
        }
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data:data,encoding:.utf8), commandString.starts(with: sessionIDCommandString){
            let newSessionID = String(commandString[commandString.index(commandString.startIndex,offsetBy: sessionIDCommandString.count)...])
            if let oldSessionID = multipeerSession.peerSessionIDs[peer]{
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            multipeerSession.peerSessionIDs[peer] = newSessionID
        }
    }
    func peerDiscovered(_ peer:PeerID) -> Bool{
        guard let multipeerSession = multipeerSession else { return false }
        if multipeerSession.connectedPeers.count > 4 {
            print("A fifth player wants to join.\nThe game is currentlylimited to four players")
            return false
        }
        else {
            return true
        }
    }
    func peerJoined(_ peer:PeerID){
        print("*** A player wants to join the game. Hold the device next to each other. ***")
        
        sendARSessionIDTo(peers: [peer])
    }
    func peerLeft(_ peer:PeerID){
        guard let multipeerSession = multipeerSession else { return }
        print("*** A player has left the game")
        
        if let sessionID = multipeerSession.peerSessionIDs[peer] {
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            multipeerSession.peerSessionIDs.removeValue(forKey: peer)
        }
    }
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier : String){
        guard let frame = arView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                arView.session.remove(anchor: anchor)
            }
        }
    }
    func session(_ session: ARSession, didOutputCollaborationData data:ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        if !multipeerSession.connectedPeers.isEmpty{
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else {
                fatalError("Unexpected failed to encode collaboration data.")
            }
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        }
        else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
}

