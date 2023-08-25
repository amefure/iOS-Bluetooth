//
//  BluePeripheralManager.swift
//  MyBluetoothTest
//
//  Created by t&a on 2023/08/24.
//

import UIKit
import CoreBluetooth

// ①：Peripheralの状態を取得しアドバタイズできる状態にする
// ②：サービス/キャラクタリスティックを追加する
// ③：アドバタイズの実装
// ④ Readリクエストを受け取った際の処理
// ⑤ Writeリクエストを受け取った際の処理(withOutは検知しない)
// ⑥ Notifyを送信するためのカスタムメソッド

class BluePeripheralManager: NSObject, ObservableObject {
    // シングルトン
    static let shared = BluePeripheralManager()
    // Centralマネージャー
    private var peripheralManager: CBPeripheralManager!
    // peripheral側のローカル名を定義
    private var peripheralName = "Test Peripheral"
    // ログ出力用
    @Published var log = ""
    
    override init() {
        super.init()
        // ① インスタンスの格納
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        // ②：サービス/キャラクタリスティックを追加する
        addService()
    }
    
    // サービス用のUUID
    private let serviceUUID = CBUUID(string:"00000000-0000-1111-1111-111111111111")
    
    // キャラクタリスティック用のUUID
    private let readCharacteristicUUID = CBUUID(string:"00000000-1111-1111-1111-111111111111")
    private let writeCharacteristicUUID = CBUUID(string:"00000000-2222-1111-1111-111111111111")
    private let writeWithoutResponseCharacteristicUUID = CBUUID(string:"00000000-2222-2222-1111-111111111111")
    private let notifyCharacteristicUUID = CBUUID(string:"00000000-3333-1111-1111-111111111111")
    private let indicateCharacteristicUUID = CBUUID(string:"00000000-4444-1111-1111-111111111111")
    
    // サービス/キャラクタリスティック保持用の変数
    private var service:CBMutableService!
    private var readCharacteristic: CBMutableCharacteristic!
    private var writeCharacteristic: CBMutableCharacteristic!
//    private var writeWithoutResponseCharacteristic: CBMutableCharacteristic!
    private var notifyCharacteristic: CBMutableCharacteristic!
    private var indicateCharacteristic: CBMutableCharacteristic!
    
    // ②：サービス/キャラクタリスティックを追加する
    private func addService() {
        // サービスの生成
        service = CBMutableService(type: serviceUUID, primary: true)
        
        // キャラクタリスティックの生成 4種類 read / write(writeWithoutResponse) / notify / indicate
        // 初期値にデータを渡すこともできるが後から上書きできなくなってしまう
        readCharacteristic = CBMutableCharacteristic(type: readCharacteristicUUID, properties: .read, value: nil, permissions: .readable)
        writeCharacteristic = CBMutableCharacteristic(type: writeCharacteristicUUID, properties: [.read,.write], value: nil, permissions: [.writeable,.readable])
        //        writeWithoutResponseCharacteristic = CBMutableCharacteristic(type: writeWithoutResponseCharacteristicUUID, properties: [.read,.writeWithoutResponse], value: nil, permissions: [.writeable,.readable])
        notifyCharacteristic = CBMutableCharacteristic(type: notifyCharacteristicUUID, properties: .notify, value: nil, permissions: .readable)
        indicateCharacteristic = CBMutableCharacteristic(type: indicateCharacteristicUUID, properties: .indicate, value: nil, permissions: .readable)
        
        // キャラクタリスティックの追加
        service.characteristics =  [
            readCharacteristic,
            writeCharacteristic,
            //            writeWithoutResponseCharacteristic,
            notifyCharacteristic,
            indicateCharacteristic
        ]
        
        // サービスの追加
        peripheralManager.add(service)
    }
    
    // ③：アドバタイズの開始
    public func startAdvertising() {
        if peripheralManager.state == .poweredOn {
            log.append("アドバタイズ開始\n")
            let serviceUUIDs = [serviceUUID]
            // アドバタイズ情報にローカルネームとサービス情報を含める
            let advertisementData:[String:Any] = [
                CBAdvertisementDataLocalNameKey: peripheralName,
                CBAdvertisementDataServiceUUIDsKey: serviceUUIDs
            ]
            peripheralManager.startAdvertising(advertisementData)
        }
    }
    
    // ③：アドバタイズの停止
    public func stopAdvertising() {
        log.append("アドバタイズ停止\n")
        peripheralManager.stopAdvertising()
    }
    
    // ⑥ Notifyを送信するためのカスタムメソッド
    public func sendNotify() {
        log.append("notifyを送信\n")
        if let data = "Notify".data(using: .utf8) {
            self.notifyCharacteristic.value = data
            peripheralManager.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: nil)
        }
    }
}

// ① CBPeripheralManagerDelegateへの準拠
extension BluePeripheralManager: CBPeripheralManagerDelegate {
    // ①Peripheralの状態が変化するタイミング (実装必須)
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            // 状態不明
            log.append("unknown\n")
        case .resetting:
            // 一時的にリセットされた状態
            log.append("resetting\n")
        case .unsupported:
            // デバイスがBluetooth機能をサポートしていない
            log.append("unsupported\n")
        case .unauthorized:
            // 使用許可がされていない
            log.append("unauthorized\n")
        case .poweredOff:
            // 電源がOFF
            log.append("poweredOff\n")
        case .poweredOn:
            // 電源がON
            // Bluetooth接続が開始できるようになります
            log.append("poweredOn\n")
        @unknown default:
            log.append("default\n")
        }
    }
    
    
    // ②：サービスが追加完了
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            log.append("サービス追加失敗\n")
        }
        log.append("サービスの追加完了\n")
    }
    
    
    // ③：アドバタイズの成功
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        log.append("アドバタイズ成功\n")
    }
    
    // ④ Readリクエストを受け取った際の処理
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        log.append("Readリクエストを受け取った\n")
        if let data = "World".data(using: .utf8) {
            request.value = data
        }
        self.peripheralManager.respond(to: request, withResult: CBATTError.success)
    }
    
    // ⑤ Writeリクエストを受け取った際の処理(withOutは検知しない)
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        log.append("writeリクエストを受け取った\n")
        for request in requests {
            self.readCharacteristic.value = request.value
            log.append("受け取った値：\(request.value)\n")
        }
        self.peripheralManager.respond(to: requests[0], withResult: CBATTError.success)
    }

}
