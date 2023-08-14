//
//  Home.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 04/08/23.
//

import SwiftUI
import RealityKit
import ARKit
import os.log

struct HomeView: View {
    @StateObject var rpsSession: MultipeerConn
    var body: some View {
        NavigationStack{
            VStack{
                NavigationLink(destination: PeerRoom(rpsSession: rpsSession)){
                    Text("Host")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    rpsSession.host()
                })
                NavigationLink(destination: PeerRoom(rpsSession: rpsSession)){
                    Text("Join")
                }
                .simultaneousGesture(TapGesture().onEnded{
                    rpsSession.join()
                })
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

//struct Home_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView(conn4VM: ConnnectFourViewModel())
//    }
//}
