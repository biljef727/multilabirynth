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
    
    func advertiser( _ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
            log.info("didReceiveInvitationFromPeer (peerID)")

            DispatchQueue.main.async {
                // Tell PairView to show the invitation alert
                self.recvdInvite = true
                // Give PairView the peerID of the peer who invited us
                self.recvdInviteFrom = peerID
                // Give PairView the invitationHandler so it can accept/deny the invitation
                self.invitationHandler = invitationHandler
            }
        }
    }
