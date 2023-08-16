//
//  MultipeerHandler.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 10/08/23.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
import ARKit
import os.log
import RealityKit

struct ARData{
    var isHost: Bool?
    var connectedDeviceName: String?
    var tableAdded = false
    var tableAddedInGuestDevice = false
}
class MultipeerConn: NSObject, ObservableObject{
    @Environment(\.dismiss) private var dismiss
    @Published var availablePeers: [MCPeerID] = []
    @Published var receivedMove: Move = .unknown
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var paired: Bool = false
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    @Published var playButton: ((Bool, MCSession?) -> Void)?
    @Published var startGame = false
    @Published var counterPlayer : Int = 1
    @Published var Hoster: Bool = false
    
    private let serviceType = "multi-labir"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    public let session: MCSession
    public let serviceAdvertiser: MCNearbyServiceAdvertiser
    public let serviceBrowser: MCNearbyServiceBrowser
    
    var arView:ARView?
    
    var log = Logger()
    init(username: String) {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
    }
    func host(){
        counterPlayer = 1
        serviceAdvertiser.startAdvertisingPeer()
        Hoster = true
    }
    func join(){
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        disconnect()
    }
    func disconnect(){
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        Hoster = false
        dismiss()
        session.disconnect()
    }
    
    func play(){
        do {
            try session.send("play!".data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            startGame = true
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //    func send(move: Move) {
    //        if !session.connectedPeers.isEmpty {
    //            log.info("sendMove: \(String(describing: move)) to \(self.session.connectedPeers[0].displayName)")
    //            do {
    //                try session.send(move.rawValue.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
    //            } catch {
    //                log.error("Error sending: \(String(describing: error))")
    //            }
    //        }
    //    }
    
    func sendExperience(data: Any) {
        if !session.connectedPeers.isEmpty {
            do {
                guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
                else {
                    fatalError("Unexpected failed to encode collaboration data.")
                }
                try session.send(encodedData, toPeers: session.connectedPeers, with: .reliable)
                
            } catch {
                log.error("Error sending: \(String(describing: error))")
            }
        }
    }
}

enum Move: String, CaseIterable, CustomStringConvertible {
    case rock, paper, scissors, unknown
    var description : String {
        switch self {
        case .rock: return "Rock"
        case .paper: return "Paper"
        case .scissors: return "Scissors"
        default: return "Thinking"
        }
    }
}
