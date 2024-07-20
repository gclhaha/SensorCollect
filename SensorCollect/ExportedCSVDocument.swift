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
                let fileWrapper = FileWrapper(regularFileWithContents: data)
                directoryWrapper.addRegularFile(withContents: data, preferredFilename: fileName)
            }
        }
        
        return directoryWrapper
    }
    
    func createCSVString(from sensorData: [[String: Any]]) -> String {
        let fieldNames = ["time", "timestamp", "accelerationX", "accelerationY", "accelerationZ", "rotationRateX", "rotationRateY", "rotationRateZ", "gravityX", "gravityY", "gravityZ", "pitch", "roll", "yaw"]
        var csvString = fieldNames.joined(separator: ",") + "\n"
        
        for dataPoint in sensorData {
            let row = fieldNames.map { field in
                if let value = dataPoint[field] {
                    return "\(value)"
                } else {
                    return "0.0"
                }
            }.joined(separator: ",")
            csvString += row + "\n"
        }
        
        return csvString
    }
}
