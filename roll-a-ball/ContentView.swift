//
//  ContentView.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 31/07/23.
//

import SwiftUI
import RealityKit
import ARKit

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

struct ContentView : View {
    
    private let arView = ARGameView()
    var body: some View {
        ZStack{
            ARViewContainer(arView: arView).edgesIgnoringSafeArea(.all)
            ControlsView(startApplyingForce: arView.startApplyingForce(direction:), stopApplyingForce: arView.stopApplyingForce)
        }
        .navigationBarBackButtonHidden(true)
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    let arView: ARGameView
    
    func makeUIView(context: Context) -> ARGameView {
        let sceneField = try! Experience.loadField()
        if let rollABall = try? Experience.loadRollABall(){
            setupComponents(in: rollABall)
            arView.scene.anchors.append(rollABall)
            setupARView()
        }
        arView.scene.anchors.append(sceneField)
        return arView
        
    }
    
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        
        config.isCollaborationEnabled = true
        
        arView.session.run(config)
    }
    
    func updateUIView(_ uiView: ARGameView, context: Context) {}
    private func setupComponents(in rollABall : Experience.RollABall){
        if let ball = rollABall.ball {
            ball.components[BallComponent.self] = BallComponent()
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
    let ballSpeed: Float = 0.01
    
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
