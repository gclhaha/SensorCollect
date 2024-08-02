import SwiftUI
import WatchConnectivity
import CoreMotion
import WatchKit

class MotionManager: NSObject, ObservableObject {
    private var motionManager = CMMotionManager()
    private var queue = OperationQueue()
    private var fileURL: URL?
    private var fileHandle: FileHandle?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    private var startTime: CFAbsoluteTime = 0
    private var currentTime: Double = 0.0


    func startUpdates(timeElapsed: Double) {
        currentTime = timeElapsed

        startTime = CFAbsoluteTimeGetCurrent()

        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "sensorData_\(Int(Date().timeIntervalSince1970)).csv"
        fileURL = tempDir.appendingPathComponent(fileName)

        do {
            FileManager.default.createFile(atPath: fileURL!.path, contents: nil, attributes: nil)
            fileHandle = try FileHandle(forWritingTo: fileURL!)
            
            // 写入CSV头
            let header = "time,timestamp,accelerationX,accelerationY,accelerationZ,rotationRateX,rotationRateY,rotationRateZ,gravityX,gravityY,gravityZ,pitch,roll,yaw\n"
            fileHandle?.write(header.data(using: .utf8)!)
        } catch {
            print("Error creating file: \(error.localizedDescription)")
            return
        }

        if motionManager.isDeviceMotionAvailable {
            print("sensor data is collecting")
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                
                let formattedTimestamp = self.formatTimestamp()
                
                let dataString = String(format: "%.3f,%@,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f,%.20f\n",
                                        self.currentTime,
                                        formattedTimestamp,
                                        data.userAcceleration.x,
                                        data.userAcceleration.y,
                                        data.userAcceleration.z,
                                        data.rotationRate.x,
                                        data.rotationRate.y,
                                        data.rotationRate.z,
                                        data.gravity.x,
                                        data.gravity.y,
                                        data.gravity.z,
                                        data.attitude.pitch,
                                        data.attitude.roll,
                                        data.attitude.yaw)
                
                self.fileHandle?.write(dataString.data(using: .utf8)!)
                self.currentTime += 0.01

                
            }
        }
    }
    
    private func formatTimestamp() -> String {
        return dateFormatter.string(from: Date())
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        fileHandle?.closeFile()
    }

    func getDataFile() -> URL? {
        return fileURL
    }
}
