import SwiftUI
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @AppStorage("sensorData") private var sensorDataStorage: Data = Data()
        @Published var savedData: [String: [[String: Any]]] = [:] {
            didSet {
                saveToAppStorage()
            }
        }
        
        override init() {
            super.init()
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }
            loadFromAppStorage()
        }
        
        func sessionDidBecomeInactive(_ session: WCSession) {}
        func sessionDidDeactivate(_ session: WCSession) {}
        
        func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error = error {
                print("WCSession activation failed with error: \(error.localizedDescription)")
                return
            }
            print("WCSession activated with state: \(activationState.rawValue)")
        }
        
        func session(_ session: WCSession, didReceive file: WCSessionFile) {
            guard let timestamp = file.metadata?["timestamp"] as? String else {
                print("Error: No timestamp in file metadata")
                return
            }
            
            do {
                let data = try String(contentsOf: file.fileURL, encoding: .utf8)
                let rows = data.components(separatedBy: .newlines)
                var sensorData: [[String: Any]] = []
                
                for row in rows.dropFirst() { // 跳过CSV头
                    let columns = row.components(separatedBy: ",")
                    if columns.count == 14 {
                        let dataPoint: [String: Any] = [
                            "time": Double(columns[0]) ?? 0,
                            "timestamp": columns[1],
                            "accelerationX": Double(columns[2]) ?? 0,
                            "accelerationY": Double(columns[3]) ?? 0,
                            "accelerationZ": Double(columns[4]) ?? 0,
                            "rotationRateX": Double(columns[5]) ?? 0,
                            "rotationRateY": Double(columns[6]) ?? 0,
                            "rotationRateZ": Double(columns[7]) ?? 0,
                            "gravityX": Double(columns[8]) ?? 0,
                            "gravityY": Double(columns[9]) ?? 0,
                            "gravityZ": Double(columns[10]) ?? 0,
                            "pitch": Double(columns[11]) ?? 0,
                            "roll": Double(columns[12]) ?? 0,
                            "yaw": Double(columns[13]) ?? 0
                        ]
                        sensorData.append(dataPoint)
                    }
                }
                
                DispatchQueue.main.async {
                    self.savedData[timestamp] = sensorData
                }
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        }
    
    public func saveToAppStorage() {
        do {
            let data = try JSONSerialization.data(withJSONObject: savedData, options: [])
            sensorDataStorage = data
        } catch {
            print("Failed to save data to AppStorage: \(error.localizedDescription)")
        }
    }
    
    public func loadFromAppStorage() {
        if let json = try? JSONSerialization.jsonObject(with: sensorDataStorage, options: []) as? [String: [[String: Any]]] {
            savedData = json
        }
    }
}
