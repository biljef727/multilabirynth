//
//  MultipeerHandlerMcNearbyServiceAdvertiserDelegate.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 10/08/23.
//

import Foundation
import MultipeerConnectivity
import SwiftUI
import os.log

extension MultipeerConn: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
    }
}
