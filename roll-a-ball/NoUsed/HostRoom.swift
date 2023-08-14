//
//  HostRoom.swift
//  roll-a-ball
//
//  Created by Billy Jefferson on 07/08/23.
//

import SwiftUI

struct HostRoom: View {
    @EnvironmentObject var conn4VM: ConnnectFourViewModel
    var body: some View {
        VStack{
            ForEach (0..<conn4VM.counterPlayer,id:\.self ){ index in
                Text("Player \(index + 1)")
            }
            .padding(.vertical)
            //Text("\(conn4VM.pesanDiterima)  aaa" )
            Spacer()
            Button(action:{
                conn4VM.play()
            }, label: {
                Text("Play")
                    .opacity(checkCount() ? 1 : 0 )
            })
            Spacer()
//            if conn4VM.isHosting == true {
//                Button(action:{
//                    conn4VM.cancel()
//                    let newView = HomeView(conn4VM: conn4VM);
//                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: newView)
//                },label:{
//                    Text("Cancel")
//                        .padding(.vertical)
//                })
//            }
//            else{
//                Button(action:{
//                    conn4VM.disjoin()
//                    let newView = HomeView(conn4VM: conn4VM);
//                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: newView)
//                },label:{
//                    Text("Disconnect")
//                        .padding(.vertical)
//                })
//            }
        }
//        .onReceive(conn4VM.counterPlayer, perform: { _ in})
        .navigationBarBackButtonHidden(true)
//        .navigationDestination(isPresented: $conn4VM.startGame) {
//            ContentView().environmentObject(conn4VM)
//        }
    }
    func checkCount()-> Bool{
        if conn4VM.counterPlayer > 1 {
            return true
        }
        else {
            return false
        }
    }
}

//struct HostRoom_Previews: PreviewProvider {
//    static var previews: some View {
//        HostRoom(conn4VM: ConnnectFourViewModel())
//    }
//}
