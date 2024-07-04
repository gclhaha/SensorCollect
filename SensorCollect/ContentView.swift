import SwiftUI
import WatchConnectivity
import UniformTypeIdentifiers

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    @Published var savedData: [String: [[String: Double]]] = [:]
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            for (timestamp, data) in message {
                if let sensorData = data as? [[String: Double]] {
                    self.savedData[timestamp] = sensorData
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var watchSessionManager = WatchSessionManager()
    @State private var isEditing = false
    @State private var selectedItems: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var showingExportAlert = false
    @State private var exportedPath = ""
    @State private var exportMessage = ""
    @State private var showDocumentPicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(watchSessionManager.savedData.keys.sorted(), id: \.self) { timestamp in
                    HStack {
                        if isEditing {
                            Image(systemName: selectedItems.contains(timestamp) ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    toggleSelection(for: timestamp)
                                }
                        }
                        NavigationLink(destination: DetailView(timestamp: timestamp, sensorData: watchSessionManager.savedData[timestamp] ?? [])) {
                            Text(timestamp)
                        }
                    }
                }
                .navigationTitle("Sensor Data")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    selectedItems.removeAll()
                                }
                            }
                        }) {
                            HStack {
                                Text(isEditing ? "Cancel" : "Choose")
                            }
                        }
                    }
                    if isEditing {
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .disabled(selectedItems.isEmpty)
                        }
                        
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                }
                            }
                            .disabled(selectedItems.isEmpty)
                            .confirmationDialog("Delete Confirmation", isPresented: $showDeleteConfirmation) {
                                Button("Delete", role: .destructive) {
                                    deleteSelectedItems()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to delete the selected items?")
                            }
                        }
                    }
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            .padding()
            .alert(isPresented: $showingExportAlert) {
                Alert(title: Text("Export Successful"), message: Text("Files exported to: \(exportedPath)"), dismissButton: .default(Text("OK")))
            }
        }
        .fileExporter(isPresented: $showDocumentPicker, document: ExportedCSVDocument(selectedItems: selectedItems, savedData: watchSessionManager.savedData), contentType: .folder, defaultFilename: "SensorCollect") { result in
            switch result {
            case .success(let url):
                exportedPath = url.path
                exportMessage = "Files exported successfully to \(exportedPath)"
                showingExportAlert = true
            case .failure(let error):
                exportMessage = "Export failed: \(error.localizedDescription)"
                showingExportAlert = true
            }
            selectedItems.removeAll()
            isEditing = false
        }
    }
    
    func toggleSelection(for timestamp: String) {
        if selectedItems.contains(timestamp) {
            selectedItems.remove(timestamp)
        } else {
            selectedItems.insert(timestamp)
        }
    }
    
    func deleteSelectedItems() {
        for timestamp in selectedItems {
            watchSessionManager.savedData.removeValue(forKey: timestamp)
        }
        selectedItems.removeAll()
        isEditing = false
    }
}


struct ExportedCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.folder] }
    var selectedItems: Set<String>
    var savedData: [String: [[String: Double]]]
    
    init(selectedItems: Set<String>, savedData: [String: [[String: Double]]]) {
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
    
    func createCSVString(from sensorData: [[String: Double]]) -> String {
        var csvString = "time,accelerationX,accelerationY,accelerationZ,rotationRateX,rotationRateY,rotationRateZ,gravityX,gravityY,gravityZ,pitch,roll,yaw\n"
        for dataPoint in sensorData {
            csvString += "\(dataPoint["time"] ?? 0.0),\(dataPoint["accelerationX"] ?? 0.0),\(dataPoint["accelerationY"] ?? 0.0),\(dataPoint["accelerationZ"] ?? 0.0),\(dataPoint["rotationRateX"] ?? 0.0),\(dataPoint["rotationRateY"] ?? 0.0),\(dataPoint["rotationRateZ"] ?? 0.0),\(dataPoint["gravityX"] ?? 0.0),\(dataPoint["gravityY"] ?? 0.0),\(dataPoint["gravityZ"] ?? 0.0),\(dataPoint["pitch"] ?? 0.0),\(dataPoint["roll"] ?? 0.0),\(dataPoint["yaw"] ?? 0.0)\n"
        }
        return csvString
    }
}

#Preview {
    ContentView()
}
