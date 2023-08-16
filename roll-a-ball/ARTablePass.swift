import UIKit
import SwiftUI
import RealityKit
import ARKit
import MultipeerConnectivity
import Combine

protocol ARPassingViewControllerDelegate:NSObjectProtocol {
    func modelChanged(model:ARData)
}

class ARPassingViewController: UIViewController, ARSessionDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, ARCoachingOverlayViewDelegate {
    
    weak var delegate: ARPassingViewControllerDelegate?
    private var session: MCSession!
    var arView:ARView!
    let coachingOverlay = ARCoachingOverlayView()
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    private var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
    private static let serviceType = "multi-labir"
    var anchor:AnchorEntity?
    var WallRight: ModelEntity!
    var WallLeft: ModelEntity!
    var WallTop: ModelEntity!
    var WallBottom: ModelEntity!
    var Ball: [ModelEntity!]
    
    var model = ARData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    func initAwal(arView:ARView){
        self.arView = arView
        view.addSubview(arView)
        let arViewTap = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
        arView.addGestureRecognizer(arViewTap)
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ARPassingViewController.serviceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ARPassingViewController.serviceType)
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
        
        arView.session.delegate = self
        arView.scene.synchronizationService = try? MultipeerConnectivityService(session: session)
        
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        coachingOverlay.frame = arView.bounds
        arView.addSubview(coachingOverlay)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // Place the table on the tapped plane.
        guard !model.tableAdded, model.isHost ?? true else {
            // If the table have alredy been added or this device is the guest, do nothing.
            return
        }
        let location = sender.location(in: arView)
        let results = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any)
        if results.first != nil {
            
            // Make anchor from tapped plane.
            let arAnchor = ARAnchor(transform: results.first!.worldTransform)
            arView.session.add(anchor: arAnchor)
            
            anchor = AnchorEntity(anchor: arAnchor)
            
            // Place table and puck in the anchor.
            WallRight.position = [1,0,0]
            WallLeft.position = [-1,0,0]
            WallTop.position = [0,0,-1]
            WallBottom.position = [0,0,1]
            
            for index in Ball {
                Ball[index].position = [0 + i * 0.4,0 + i * 0.4,0 + i * 0.4]
            }
            
            WallRight.scale = [1,1,1]
            WallLeft.scale = [1,1,1]
            WallTop.scale = [1,1,1]
            WallBottom.scale = [1,1,1]
            
            anchor!.addChild(WallRight)
            anchor!.addChild(WallLeft)
            anchor!.addChild(WallTop)
            anchor!.addChild(WallBottom)
            
            arView.scene.addAnchor(anchor!)
            
            model.tableAdded = true
            
            if let isHost = model.isHost {
                if isHost {
                    // If connected, let guest know table added.
                    sendHostTableAdded()
                }
            } else {
                // If not connected, set non player character.
//                setNonPlayerCharacter()
            }
        }
    }
    
//    func sendTap() -> some View {
//        let arViewTap = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
//        arView.addGestureRecognizer(arViewTap)
//        return arView
//    }
    
    private func sendHostTableAdded() {
        let guestTableAddedString = "hostTableAdded"
        guard let stringData = guestTableAddedString.data(using: .ascii) else {return}
        sendToAllPeers(stringData)
    }
    
    private func sendToAllPeers(_ data: Data) {
        // Send data to another peer.
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    private func hostTableAdded() {
        model.tableAdded = true
        delegate?.modelChanged(model: model)
    }
    
    private func tableSharedFromHost() {
        model.tableAddedInGuestDevice = true
        delegate?.modelChanged(model: model)
        let guestTableAddedString = "guestTableAdded"
        guard let stringData = guestTableAddedString.data(using: .ascii) else {return}
        sendToAllPeers(stringData)
    }
    
    private func removeExistingTable() {
        // [Guest] Remove the existing table.
        self.anchor?.removeFromParent()
    }
    
    private func didReceiveGameState() {
        // [Guest] Update game state with received state.
        if !(model.isHost ?? false) {
            delegate?.modelChanged(model: model)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let participantAnchor = anchor as? ARParticipantAnchor {
                let anchorEntity = AnchorEntity(anchor: participantAnchor)
                arView.scene.addAnchor(anchorEntity)
            }
        }
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let receivedString = String(data: data, encoding: .ascii) {
            switch receivedString {
            case "hostTableAdded" :
                
                // [Guest]
                hostTableAdded()

            case "guestTableAdded" :
                // [Host] The table shared with the guest.
                model.tableAddedInGuestDevice = true
                delegate?.modelChanged(model: model)
                // Game start
//                setupMultiPlayersGame()
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let context = context else {return}
        guard let invitationTimeString = String(data:context,encoding: .ascii) else {return}
        guard let invitationTime = Int(invitationTimeString) else {return}
//        model.isHost = browsingTime < invitationTime
        model.connectedDeviceName = peerID.displayName
        delegate?.modelChanged(model: model)
//        setupMultiPlayersGame()
//        gameStateChanged()
        if !self.model.isHost! {
            // [Guest]
            removeExistingTable()
        } else if model.tableAdded {
            // If host table has been already added, let guest know it and move guest's device.
            sendHostTableAdded()
        }
        invitationHandler(true, self.session)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        guard let browsingTime = browsingTime else {return}
//        let timeData = browsingTime.description.data(using: .ascii)
//        browser.invitePeer(peerID, to: session, withContext: timeData, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
}

