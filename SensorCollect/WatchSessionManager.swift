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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async {
            if let timestamp = userInfo["timestamp"] as? String, let sensorData = userInfo["data"] as? [[String: Any]] {
                if self.savedData[timestamp] != nil {
                    self.savedData[timestamp]?.append(contentsOf: sensorData)
                } else {
                    self.savedData[timestamp] = sensorData
                }
            }
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
