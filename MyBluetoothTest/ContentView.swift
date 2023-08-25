//
//  ContentView.swift
//  MyBluetoothTest
//
//  Created by t&a on 2023/08/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var blueCentralManager = BlueCentralManager.shared
    @ObservedObject var bluePeripheralManager = BluePeripheralManager.shared
    
    @State var select = 0
    var body: some View {
        TabView(selection: $select) {
            // MARK : - Central
            VStack{
                TextEditor(text: $blueCentralManager.log)
                
                Divider()
                
                HStack{
                    Button {
                        blueCentralManager.observeNotify()
                    } label: {
                        Text("Notify検知開始")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Button {
                        blueCentralManager.stopNotify()
                    } label: {
                        Text("Notify検知停止")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                
                HStack{
                    
                    
                    Button {
                        blueCentralManager.readData()
                    } label: {
                        Text("読み込み")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        
                    
                    Button {
                        blueCentralManager.registerData()
                    } label: {
                        Text("書き込み")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        
                }
                HStack{
                    Button {
                        blueCentralManager.startScan()
                    } label: {
                        Text("スキャン")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Button {
                        blueCentralManager.startScan()
                    } label: {
                        Text("切断")
                    }.padding()
                        .frame(width:150)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                
            }.tabItem{
                Text("Central")
            }.tag(1)
            
            // MARK : - Peripheral
            VStack{
                TextEditor(text: $bluePeripheralManager.log)
                
                Divider()
                
                Button {
                    bluePeripheralManager.sendNotify()
                } label: {
                    Text("Notify通知")
                }.padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                
                Button {
                    bluePeripheralManager.stopAdvertising()
                } label: {
                    Text("アドバタイズ停止")
                }.padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                
                Button {
                    bluePeripheralManager.startAdvertising()
                } label: {
                    Text("アドバタイズ開始")
                }.padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }.tabItem{
                Text("Peripheral")
            }.tag(2)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
