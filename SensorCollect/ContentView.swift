import SwiftUI
import WatchConnectivity
import UniformTypeIdentifiers

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
                        NavigationLink(destination: DetailView(timestamp: timestamp, sensorData: convertToDoubleDictionary(watchSessionManager.savedData[timestamp] ?? []))) {
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
            .onAppear {
                watchSessionManager.loadFromAppStorage()
            }
            .overlay(
                HStack {
                    Spacer()
                    Text("SensorCollect")
                        .font(.headline)
                        .padding(.top, 10)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top),
                alignment: .topTrailing
            )
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
    
    func convertToDoubleDictionary(_ data: [[String: Any]]) -> [[String: Double]] {
        return data.compactMap { dataPoint in
            var doubleDataPoint: [String: Double] = [:]
            for (key, value) in dataPoint {
                if let doubleValue = value as? Double {
                    doubleDataPoint[key] = doubleValue
                }
            }
            return doubleDataPoint
        }
    }
}

#Preview {
    ContentView()
}
