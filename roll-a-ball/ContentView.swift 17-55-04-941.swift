//
//  ContentView.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 31/07/23.
//

import SwiftUI
import RealityKit
import ARKit
import MultipeerSession
import UIKit

enum ForceDirection{
    case up, down, left, right
    
    var symbol:String{
        switch self {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .left:
            return "arrow.left.circle.fill"
        case .right:
            return "arrow.right.circle.fill"
        }
    }
    var vector:SIMD3<Float> {
        switch self {
        case .up:
            return SIMD3<Float>(0,0,-1)
        case .down:
            return SIMD3<Float>(0,0,1)
        case .left:
            return SIMD3<Float>(-1,0,0)
        case .right:
            return SIMD3<Float>(1,0,0)
            
        }
    }
}

class SapimanViewController: UIViewController {
    static var shared = SapimanViewController()
    var arView:ARView = ARView()
    var multipeerSession: MultipeerSession?
    var sessionIDObservation:NSKeyValueObservation?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.arView = ARView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        self.arView.frame = view.bounds
//        let xx = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        xx.backgroundColor = .red
//        self.view.addSubview(xx)
        self.arView.backgroundColor = .blue
        self.view.addSubview(self.arView)
        setupARView()
        
//        setupMultipeerSession()
        
        self.arView.session.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        self.arView.addGestureRecognizer(tapGestureRecognizer)
        
        
    }
    func setupARView() {
        self.arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        self.arView.session.run(config)
    }
    
    func setupMultipeerSession(){
        sessionIDObservation = observe(\.arView.session.identifier, options: [.new]){
            object , change in print("SessionID Changed To: \(change.newValue!)")
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers:multipeerSession.connectedPeers)
        }
        multipeerSession = MultipeerSession(serviceName: "multiuser-ar", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
    }
    
    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        
        let anchor = ARAnchor(name:"LaaserBlue",transform: self.arView.cameraTransform.matrix)
        self.arView.session.add(anchor:anchor)
    }
    
    func placeObject(named entityName : String, for anchor: ARAnchor){
//        @EnvironmentObject var conn4VM: ConnnectFourViewModel
//        if conn4VM.isHosting{
            let sceneField = try! Experience.loadField()
            arView.scene.anchors.append(sceneField)
            if let rollABall = try? Experience.loadRollABall(){
//                setupComponents(in: rollABall)
                arView.scene.anchors.append(rollABall)
            }
//        }
//        if conn4VM.isConnected{
//            if let rollABall = try? Experience.loadRollABall(){
//                setupComponents(in: rollABall)
//                arView.scene.anchors.append(rollABall)
//            }
//        }
//        return arView
    }
    
    func startApplyingForce(direction:ForceDirection){
        //        print("apply Force: \(direction.symbol)")
        if let ball = self.arView.scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = direction
            ball.components[BallComponent.self] = ballState
        }
    }
    func stopApplyingForce(){
        //        print("stop Force")
        if let ball = self.arView.scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = nil
            ball.components[BallComponent.self] = ballState
        }
    }
}

extension SapimanViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == "LaserBlue" {
                placeObject(named:anchorName,for: anchor)
            }
            
            if let participantAnchor = anchor as? ARParticipantAnchor {
                print("Successfully connected with antoher user!")
                
                let anchorEntity = AnchorEntity(anchor:participantAnchor)
                
                let mesh = MeshResource.generateSphere(radius: 0.03)
                let color = UIColor.red
                let material = SimpleMaterial(color:color,isMetallic:false )
                let coloredSphere = ModelEntity(mesh:mesh,materials:[material])
                
                anchorEntity.addChild(coloredSphere)
                
                self.arView.scene.addAnchor(anchorEntity)
            }
        }
    }
}
extension SapimanViewController{
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



struct ContentView : View {

//    private let arView = ARGameView()
    var body: some View {
        ZStack{
            CisCable()
//            ARViewContainer(arView: arView).edgesIgnoringSafeArea(.all)
            ControlsView(startApplyingForce: SapimanViewController.shared.startApplyingForce(direction:), stopApplyingForce: SapimanViewController.shared.stopApplyingForce)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct CisCable:UIViewControllerRepresentable{
    func makeUIViewController(context: Context) -> SapimanViewController {
        return SapimanViewController.shared
    }
    
    func updateUIViewController(_ uiViewController: SapimanViewController, context: Context) {
        
    }
    
//    typealias UIViewControllerType = SapimanViewController
    
    

    
    
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var conn4VM: ConnnectFourViewModel
    
    @State var multipeerSession: MultipeerSession?
    @State var sessionIDObservation:NSKeyValueObservation?
    let arView: ARGameView
    
    func makeUIView(context: Context) -> ARGameView {
        setupARView()
//        setupMultipeerSession()
        if conn4VM.isHosting{
            let sceneField = try! Experience.loadField()
            arView.scene.anchors.append(sceneField)
            if let rollABall = try? Experience.loadRollABall(){
                setupComponents(in: rollABall)
                arView.scene.anchors.append(rollABall)
            }
        }
        if conn4VM.isConnected{
            if let rollABall = try? Experience.loadRollABall(){
                setupComponents(in: rollABall)
                arView.scene.anchors.append(rollABall)
            }
        }
        return arView
        
    }
    
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        arView.session.run(config)
    }
//    func setupMultipeerSession(){
//
//        sessionIDObservation = observe(\.arView.session.identifier, options: [.new]){
//            object , change in print("SessionID Changed To: \(change.newValue!)")
//            guard let multipeerSession = self.multipeerSession else { return }
//            self.sendARSessionIDTo(peers:multipeerSession.connectedPeers)
//        }
//        multipeerSession = MultipeerSession(serviceName: "multiuser-ar", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
//
//
//    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    private func setupComponents(in rollABall : Experience.RollABall){
        if let ball = rollABall.ball {
            ball.components[BallComponent.self] = BallComponent()
        }
    }
}
extension ARViewContainer{
    private func sendARSessionIDTo(peers: [PeerID]){
        guard let multipeerSession = multipeerSession else { return }
        let idString = arView.session.identifier.uuidString
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

struct BallComponent: Component {
    static let query = EntityQuery(where: .has(BallComponent.self))
    var direction: ForceDirection?
}
class ARGameView: ARView{
    func startApplyingForce(direction:ForceDirection){
        //        print("apply Force: \(direction.symbol)")
        if let ball = scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = direction
            ball.components[BallComponent.self] = ballState
        }
    }
    func stopApplyingForce(){
        //        print("stop Force")
        if let ball = scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = nil
            ball.components[BallComponent.self] = ballState
        }
    }
}
class BallPhysicsSystem: System {
    let ballSpeed: Float = 0.05
    
    required init(scene:RealityKit.Scene){
        
    }
    func update(context: SceneUpdateContext) {
        if let ball = context.scene.performQuery(BallComponent.query).first{
            move(ball:ball)
        }
    }
    private func move(ball:Entity){
        guard let ballState = ball.components[BallComponent.self] as? BallComponent,
              let physicsBody = ball as? HasPhysicsBody else {
            return
        }
        if let forceDirection = ballState.direction?.vector {
            let impulse = ballSpeed * forceDirection
            physicsBody.applyLinearImpulse(impulse, relativeTo: nil)
        }
    }
    
}

struct ControlsView: View {
    
    let startApplyingForce:(ForceDirection) -> Void
    let stopApplyingForce:() -> Void
    
    var body: some View{
        VStack{
            Spacer()
            HStack{
                Spacer()
                arrowButton(direction: .up)
                Spacer()
            }
            HStack{
                arrowButton(direction: .left)
                Spacer()
                arrowButton(direction: .right)
            }
            HStack{
                Spacer()
                arrowButton(direction: .down)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    func arrowButton(direction:ForceDirection) -> some View {
        Image(systemName: direction.symbol).resizable().frame(width: 75, height: 75)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged{ _ in
                    startApplyingForce(direction)
                }
                .onEnded{ _ in
                    stopApplyingForce()
                }
            )
    }
    
}
extension Sequence {
    var first : Element? {
        var iterator = self.makeIterator()
        return iterator.next()
    }
}
#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
