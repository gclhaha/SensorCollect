//
//  ExportedCSVDocument.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/10.
//

import SwiftUI
import WatchConnectivity
import UniformTypeIdentifiers

struct ExportedCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.folder] }
    var selectedItems: Set<String>
    var savedData: [String: [[String: Any]]]
    
    init(selectedItems: Set<String>, savedData: [String: [[String: Any]]]) {
        self.selectedItems = selectedItems
        self.savedData = savedData
    }
    
    init(configuration: ReadConfiguration) throws {
        self.selectedItems = []
        self.savedData = [:]
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let directoryWrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        for timestamp in selectedItems {
            if let sensorData = savedData[timestamp] {
                let csvString = createCSVString(from: sensorData)
                let fileName = "\(timestamp.replacingOccurrences(of: ":", with: "-")).csv"
                let data = Data(csvString.utf8)
                _ = FileWrapper(regularFileWithContents: data)
                directoryWrapper.addRegularFile(withContents: data, preferredFilename: fileName)
            }
        }
        
        return directoryWrapper
    }
    
    func createCSVString(from sensorData: [[String: Any]]) -> String {
        var csvString = "time,timestamp,accelerationX,accelerationY,accelerationZ,rotationRateX,rotationRateY,rotationRateZ,gravityX,gravityY,gravityZ,pitch,roll,yaw\n"
        for dataPoint in sensorData {
            csvString += "\(dataPoint["time"] ?? 0.0),\(dataPoint["timestamp"] ?? ""),\(dataPoint["accelerationX"] ?? 0.0),\(dataPoint["accelerationY"] ?? 0.0),\(dataPoint["accelerationZ"] ?? 0.0),\(dataPoint["rotationRateX"] ?? 0.0),\(dataPoint["rotationRateY"] ?? 0.0),\(dataPoint["rotationRateZ"] ?? 0.0),\(dataPoint["gravityX"] ?? 0.0),\(dataPoint["gravityY"] ?? 0.0),\(dataPoint["gravityZ"] ?? 0.0),\(dataPoint["pitch"] ?? 0.0),\(dataPoint["roll"] ?? 0.0),\(dataPoint["yaw"] ?? 0.0)\n"
        }
        return csvString
    }
}
