//
//  Home.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 04/08/23.
//

import SwiftUI
import RealityKit
import ARKit

struct HomeView: View {
    @ObservedObject var conn4VM = ConnnectFourViewModel()
    @State var isActive = false
    @State var isHost = false
    var body: some View {
        NavigationStack{
            if isActive{
                HostRoom().environmentObject(conn4VM)
            }
            else{
                VStack{
                    Spacer()
                    VStack {
                        Spacer()
                        Button("Host") {
                            conn4VM.host()
                            self.isActive = true
                            self.isHost = true
                        }
                        .font(.largeTitle)
                        Spacer()
                        Button("Join") {
                            conn4VM.join()
                            self.isActive = true
                        }
                        .font(.largeTitle)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }
}

//struct Home_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView(conn4VM: ConnnectFourViewModel())
//    }
//}
