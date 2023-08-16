//
//  PeerRoom.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 10/08/23.
//

import SwiftUI
import RealityKit
import ARKit
import os.log

struct PeerRoom: View {
    @ObservedObject var rpsSession: MultipeerConn
    var logger = Logger()
    var body: some View {
        ZStack{
            VStack{
                if (rpsSession.Hoster || rpsSession.paired){
                    Text("Host")
                    ForEach (1..<rpsSession.counterPlayer,id:\.self ){ index in
                        Text("Player \(index)")
                    }
                }
                if (!rpsSession.paired) {
                    HStack {
                        List(rpsSession.availablePeers, id: \.self) { peer in
                            Button(peer.displayName) {
                                rpsSession.serviceBrowser.invitePeer(peer, to: rpsSession.session, withContext: nil, timeout: 30)
                            }
                        }
                    }
                    .alert("Received an invite from \(rpsSession.recvdInviteFrom?.displayName ?? "ERR")!", isPresented: $rpsSession.recvdInvite) {
                        Button("Accept invite") {
                            if (rpsSession.invitationHandler != nil) {
                                rpsSession.invitationHandler!(true, rpsSession.session)
                            }
                        }
                        Button("Reject invite") {
                            if (rpsSession.invitationHandler != nil) {
                                rpsSession.invitationHandler!(false, nil)
                            }
                        }
                    }
                }
                Spacer()
                //hanya hoster yg bisa start
                if (rpsSession.Hoster && rpsSession.paired){
                    NavigationLink{
                        ContentView(isHost:rpsSession.Hoster).environmentObject(rpsSession)
                    } label: {
                        Text("Play")
                    }
                    .simultaneousGesture(TapGesture().onEnded{
                        rpsSession.play()
                    })
                    .disabled(rpsSession.paired ? false : true)
                }
            }
            VStack{
                HStack{
                    NavigationLink(destination: HomeView(rpsSession: rpsSession)){
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .simultaneousGesture(TapGesture().onEnded{
                        rpsSession.disconnect()
                    })
                    Spacer()
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $rpsSession.startGame) {
            ContentView(isHost:rpsSession.Hoster).environmentObject(rpsSession)
        }
    }
}

struct PeerRoom_Previews: PreviewProvider {
    static var previews: some View {
        PeerRoom(rpsSession: MultipeerConn(username: "Hello"))
    }
}
