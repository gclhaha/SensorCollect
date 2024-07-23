import SwiftUI
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
        let dispatchGroup = DispatchGroup()

        for timestamp in selectedItems {
            if let sensorData = savedData[timestamp] {
                let fileName = "\(timestamp.replacingOccurrences(of: ":", with: "-")).csv"
                let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
                
                dispatchGroup.enter()
                DispatchQueue.global(qos: .utility).async {
                    do {
                        try self.writeCSV(sensorData: sensorData, to: fileURL)
                        
                        let data = try Data(contentsOf: fileURL)
                        let fileWrapper = FileWrapper(regularFileWithContents: data)
                        DispatchQueue.main.async {
                            directoryWrapper.addRegularFile(withContents: data, preferredFilename: fileName)
                            dispatchGroup.leave()
                        }
                    } catch {
                        print("Error writing to file: \(error.localizedDescription)")
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.wait()
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
    
    func writeCSV(sensorData: [[String: Any]], to fileURL: URL) throws {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        } else {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else {
            throw NSError(domain: "Unable to open file handle", code: 1, userInfo: nil)
        }
        
        let batchSize = 1000
        for i in stride(from: 0, to: sensorData.count, by: batchSize) {
            let endIndex = min(i + batchSize, sensorData.count)
            let batchData = sensorData[i..<endIndex]
            let csvString = createCSVString(from: Array(batchData))
            if let data = csvString.data(using: .utf8) {
                fileHandle.write(data)
            }
        }
        
        fileHandle.closeFile()
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
