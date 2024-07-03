import SwiftUI
import WatchConnectivity

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
    @State private var isEditing = false // 是否处于编辑模式
    @State private var selectedItems: Set<String> = [] // 存储选中的条目
    @State private var showDeleteConfirmation = false // 是否显示删除确认弹窗
    @State private var showingExportAlert = false // 导出完成提示
    @State private var exportedPath = "" // 导出的路径
    @State private var exportMessage = "" // 导出提示信息
    
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
                                exportToCSV()
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
    }
    
    // 切换选择状态
    func toggleSelection(for timestamp: String) {
        if selectedItems.contains(timestamp) {
            selectedItems.remove(timestamp)
        } else {
            selectedItems.insert(timestamp)
        }
    }
    
    // 删除选中的条目
    func deleteSelectedItems() {
        for timestamp in selectedItems {
            watchSessionManager.savedData.removeValue(forKey: timestamp)
        }
        selectedItems.removeAll()
        isEditing = false
    }
    
    // 删除单个条目
    func deleteItem(at offsets: IndexSet) {
        let sortedKeys = watchSessionManager.savedData.keys.sorted()
        if let index = offsets.first {
            let keyToRemove = sortedKeys[index]
            watchSessionManager.savedData.removeValue(forKey: keyToRemove)
        }
    }
    
    
    func exportToCSV() {
        let fileManager = FileManager.default
        // 获取 Documents 文件夹路径
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportMessage = "Error getting documents directory"
            showingExportAlert = true
            return
        }
        
        for timestamp in selectedItems {
            guard let sensorData = watchSessionManager.savedData[timestamp] else { continue }
            
            let csvString = createCSVString(from: sensorData)
            let fileName = "\(timestamp.replacingOccurrences(of: ":", with: "-")).csv" // 确保文件名没有非法字符
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                exportMessage = "Error writing CSV file: \(error)"
                showingExportAlert = true
                return
            }
        }
        
        // 导出完成后，取消选择并退出编辑模式
        selectedItems.removeAll()
        isEditing = false
        
        // 显示导出成功的弹窗
        exportMessage = "Files exported successfully."
        showingExportAlert = true
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
