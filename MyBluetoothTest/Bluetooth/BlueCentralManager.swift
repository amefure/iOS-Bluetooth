//
//  BlueCentralManager.swift
//  MyBluetoothTest
//
//  Created by t&a on 2023/08/23.
//

import UIKit
import CoreBluetooth

// ①：Centralの状態を取得しスキャンできる状態にする
// ②：スキャンの実装
// ③：ペリフェラルの検出と接続
// ④：ペリフェラルの接続結果を取得
// ⑤：サービス/キャラクタリスティックの取得
// ⑥ ペリフェラルから値を取得する
// ⑦ ペリフェラルに値を書き込む

class BlueCentralManager: NSObject, ObservableObject {
    // シングルトン
    static let shared = BlueCentralManager()
    // Centralマネージャー
    private var centralManager: CBCentralManager!
    
    // ③：ペリフェラルの検出
    private var connectPeripheral: CBPeripheral!
    
    // ログ出力用
    @Published var log = ""
    
    // MARK: - ペリフェラル側の実装に合わせて定義する
    // peripheral側のローカル名を定義
    private var peripheralName = "Test Peripheral"
    
    // サービス用のUUID
    private let serviceUUID = CBUUID(string:"00000000-0000-1111-1111-111111111111")
    
    // キャラクタリスティック用のUUID
    private let readCharacteristicUUID = CBUUID(string:"00000000-1111-1111-1111-111111111111")
    private let writeCharacteristicUUID = CBUUID(string:"00000000-2222-1111-1111-111111111111")
    private let notifyCharacteristicUUID = CBUUID(string:"00000000-3333-1111-1111-111111111111")
    private let indicateCharacteristicUUID = CBUUID(string:"00000000-4444-1111-1111-111111111111")
    
    // キャラクタリスティック保持用
    private var readCharacteristic: CBCharacteristic!
    private var writeCharacteristic: CBCharacteristic!
    private var notifyCharacteristic: CBCharacteristic!
    private var indicateCharacteristic: CBCharacteristic!
    // MARK: - ペリフェラル側の実装に合わせて定義する
    
    override init() {
        super.init()
        // ① インスタンスの格納
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // ②：スキャンの実装
    public func startScan() {
        if centralManager.state == .poweredOn {
            log.append("スキャン開始\n")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    // ⑥ キャラクタリスティックから値を取得する
    public func readData() {
        if readCharacteristic != nil {
            connectPeripheral.readValue(for: readCharacteristic)
        }
    }
    
    // ⑧ Notifyを検知開始する
    public func observeNotify() {
        if notifyCharacteristic != nil {
            // Notifyの検知を開始
            connectPeripheral.setNotifyValue(true, for: notifyCharacteristic)
        }
    }
    // ⑧ Notifyを検知停止する
    public func stopNotify() {
        if notifyCharacteristic != nil {
            // Notifyの検知を停止
            connectPeripheral.setNotifyValue(false, for: notifyCharacteristic)
        }
    }
    
    // ペリフェラルとの接続を切断する
    public func disConnect() {
        if connectPeripheral != nil {
            centralManager.cancelPeripheralConnection(connectPeripheral)
        }
    }
}

// ① CBCentralManagerDelegateへの準拠
extension BlueCentralManager: CBCentralManagerDelegate {
    // ① Centralの状態が変化するタイミング (実装必須)
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
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
            log.append("poweredOn\n")
        @unknown default:
            log.append("default\n")
        }
    }
    
    // ③：ペリフェラルの検出
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // advertisementDataからローカル名を取得
        if let localName = advertisementData["kCBAdvDataLocalName"] as? String{
            // 取得したローカル名とマッチしたいペリフェラル名を比較
            if  localName == self.peripheralName {
                log.append("対象のペリフェラル：\(localName)を検出\n")
                self.connectPeripheral = peripheral
                // ペリフェラルと接続
                central.connect(peripheral, options: nil)
                // スキャンの停止
                centralManager.stopScan()
            }
        }
    }
    
    // ④：ペリフェラルの接続結果を取得：成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.append("接続成功\n")
        // ⑤：サービス/キャラクタリスティックの取得
        peripheral.delegate = self
        // サービスの探索開始
        let services = [serviceUUID]
        peripheral.discoverServices(services) // nilを渡すことも可能だが電池消費が激しい
    }
    // ④：ペリフェラルの接続結果を取得：失敗
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.append("接続失敗\n")
    }
    
}
// ⑤：サービス/キャラクタリスティックの取得
extension BlueCentralManager: CBPeripheralDelegate {
    
    // ⑤：サービスが見つかった際に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log.append("サービスが見つかりました\n")
        // servicesプロパティから配列形式のCBServiceが取得できる
        if let services:Array<CBService> = peripheral.services {
            
            for service in services {
                let characteristicUUIDs = [
                    readCharacteristicUUID,
                    writeCharacteristicUUID,
                    notifyCharacteristicUUID,
                    indicateCharacteristicUUID
                ]
                // キャラクタリスティックを探索開始
                // nilを渡すことも可能だが電池消費が激しい
                peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
            }
        }
    }
    
    // ⑤：キャラクタリスティックが見つかった際に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // characteristicsプロパティから配列形式のCBCharacteristicが取得できる
        if let characteristics:Array<CBCharacteristic> = service.characteristics {
            log.append("キャラクタリスティックは\(characteristics.count)個見つかりました\n")
            for characteristic in characteristics {
                // 一致するUUIDを検索してそれぞれに格納
                if characteristic.uuid == readCharacteristicUUID {
                    readCharacteristic = characteristic
                } else if characteristic.uuid == writeCharacteristicUUID {
                    writeCharacteristic = characteristic
                } else if characteristic.uuid == notifyCharacteristicUUID {
                    notifyCharacteristic = characteristic
                } else if characteristic.uuid == indicateCharacteristicUUID {
                    indicateCharacteristic = characteristic
                }
            }
        }
    }
    
    
    // ⑥ キャラクタリスティックから値を取得する
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        log.append("ペリフェラルから値を取得しました。\n")
        log.append("キャラクタリスティックの値：\(characteristic.value)\n")
    }
    
    
    // ⑦ ペリフェラルに値を書き込む
    public func registerData() {
        if writeCharacteristic != nil {
            connectPeripheral.writeValue("Hello".data(using: .utf8)!, for: writeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // ⑦ 書き込み成功時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        log.append("書き込み成功\n")
    }
    
    // ペリフェラルからの切断
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.append("ペリフェラルから切断されました。\n")
    }
}
