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
                        // 只在编辑模式且有选中项时显示删除按钮
                        if isEditing {
                            ToolbarItem(placement: .bottomBar) {
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
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
}

#Preview {
    ContentView()
}
