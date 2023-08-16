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
import FocusEntity

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

class GameController: UIViewController {
    static var shared = GameController()
    var arView:ARView = ARView()
    var rpsSession:MultipeerConn?
    var multipeerSession: MultipeerSession?
    var sessionIDObservation:NSKeyValueObservation?
    var tapOne : Bool = false
    var isHost: Bool? = false
    var arPassing : ARPassingViewController?
    var model = ARData()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arPassing?.initAwal(arView: arView)
        self.arView = ARView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        self.arView.frame = view.bounds
        self.arView.backgroundColor = .blue
        self.view.addSubview(self.arView)
        setupARView()
        ContentStoryBoard(multipeerSession: self.multipeerSession,arView:self.arView).setupMultipeerSession()
        let _ = print("view did appear")
        
        self.arView.session.delegate = self
        
//        let arViewTap = UITapGestureRecognizer(target: self, action: #selector(arPassing!.tapped(sender:)))
//        self.arView.addGestureRecognizer(arViewTap)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        self.arView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setupARView() {
        self.arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        let focusSquare = FocusEntity(on: arView, focus: .classic)
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        self.arView.session.run(config)
    }
    
    
    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        let anchor = ARAnchor(name:"Ball",transform: self.arView.cameraTransform.matrix)
        self.arView.session.add(anchor:anchor)
    }
    
    func placeObject(named entityName : String, for anchor: ARAnchor){
        if !tapOne{
            if (isHost == true){
                tapOne = true
//                let sceneField = try! Experience.loadField()
//                arView.scene.anchors.append(sceneField)
                if let rollABall = try? Experience.loadRollABall(){
                    setupComponents(in: rollABall)
                    arView.scene.anchors.append(rollABall)
                }
            }
            else{
                tapOne = true
                if let rollABall = try? Experience.loadRollABall(){
                    setupComponents(in: rollABall)
                    arView.scene.anchors.append(rollABall)
                }
            }
        }
    }
    
    func startApplyingForce(direction:ForceDirection){
        if let ball = self.arView.scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = direction
            ball.components[BallComponent.self] = ballState
        }
    }
    func stopApplyingForce(){
        if let ball = self.arView.scene.performQuery(BallComponent.query).map({ $0 }).first {
            var ballState = ball.components[BallComponent.self] as? BallComponent
            ballState?.direction = nil
            ball.components[BallComponent.self] = ballState
        }
    }
    private func setupComponents(in rollABall : Experience.RollABall){
        if let ball = rollABall.ball {
            ball.components[BallComponent.self] = BallComponent()
        }
    }
}

extension GameController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == "Ball" {
                placeObject(named:anchorName,for: anchor)
            }
        }
    }
}
struct ContentView : View {
    @EnvironmentObject var rpsSession: MultipeerConn
    @State var model:ARData?
    var isHost : Bool
    var body: some View {
        ZStack{
            gameStart()
            LabyrinView(rpsSession: rpsSession)
            ControlsView(startApplyingForce: GameController.shared.startApplyingForce(direction:), stopApplyingForce: GameController.shared.stopApplyingForce)
            
//                .onChange(of: GameController.shared., perform: <#T##(Equatable) -> Void##(Equatable) -> Void##(_ newValue: Equatable) -> Void#>)
        }
        .task{
            GameController.shared.isHost = isHost
            GameController.shared.rpsSession = rpsSession
        }
        .navigationBarBackButtonHidden(true)
    }
    func gameStart() -> Text{
        var textString: String = ""
        var textColor: Color = .gray
        
        switch model?.isHost {
        case true:
            // host
            switch model?.tableAdded {
            case true:
                // table has been added
                switch model?.tableAddedInGuestDevice {
                case true:
                    // table has been shared
                    //                    textString = "(You) black \(model?.gameState.hostScore ?? 0) : \(model?.gameState.guestScore ?? 0) white (\(model?.connectedDeviceName ?? "other device"))"
                    textColor = .black
                default:
                    // table has not been shared
                    textString = "Move device to share the table position with \(model?.connectedDeviceName ?? "other device")"
                }
                
            default:
                // table has not been added
                textString = "Place board by tapping plane."
            }
            
        case false:
            // guest
            switch model?.tableAdded  {
            case true:
                // table has been added
                switch model?.tableAddedInGuestDevice {
                case true:
                    // table has been shared
                    //                    textString = "(\(model?.connectedDeviceName ?? "other device")) black \(model?.gameState.hostScore ?? 0) : \(model?.gameState.guestScore ?? 0) white (You)"
                    textColor = .white
                    
                default:
                    // table has not been shared
                    textString = "Move device to share the table position from \(model?.connectedDeviceName ?? "other device")"
                }
            default:
                // table has not been added
                textString = "Please wait the table will be added by \(model?.connectedDeviceName ?? "other device")"
            }
            
        default:
            // not connected
            switch model?.tableAdded {
            case true: // table added
                //                textString = "(You) black \(model?.gameState.hostScore ?? 0) : \(model?.gameState.guestScore ?? 0) white (Auto)"
                textColor = .black
            default:
                //no table
                textString = "Place board by tapping plane."
            }
        }
        return Text(textString)
            .font(.system(size: 24, weight:.bold))
            .foregroundColor(textColor)
    }
}


struct LabyrinView:UIViewControllerRepresentable{
    @ObservedObject var rpsSession: MultipeerConn
    func makeUIViewController(context: Context) -> GameController {
        return GameController.shared
    }
    
    func updateUIViewController(_ uiViewController: GameController, context: Context) {
        
    }
    
}

struct BallComponent: Component {
    static let query = EntityQuery(where: .has(BallComponent.self))
    var direction: ForceDirection?
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
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
