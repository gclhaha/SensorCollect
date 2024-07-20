import SwiftUI
import Charts

struct DetailView: View {
    let timestamp: String
    let sensorData: [[String: Double]]
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Sensor Data for \(timestamp)")
                    .font(.headline)
                    .padding()
                
                Group {
                    Text("Accelerometer Data")
                        .font(.title2)
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let x = data["accelerationX"] {
                                LineMark(x: .value("Time", time), y: .value("X", x))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let y = data["accelerationY"] {
                                LineMark(x: .value("Time", time), y: .value("Y", y))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let z = data["accelerationZ"] {
                                LineMark(x: .value("Time", time), y: .value("Z", z))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
                
                Group {
                    Text("Gyroscope Data")
                        .font(.title2)
                        .padding(.top)
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let x = data["rotationRateX"] {
                                LineMark(x: .value("Time", time), y: .value("X", x))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let y = data["rotationRateY"] {
                                LineMark(x: .value("Time", time), y: .value("Y", y))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    Chart {
                        ForEach(sensorData, id: \.self) { data in
                            if let time = data["time"], let z = data["rotationRateZ"] {
                                LineMark(x: .value("Time", time), y: .value("Z", z))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Detail View")
    }
}

#Preview {
    DetailView(timestamp: "2024-07-02 12:00:00", sensorData: [
        ["time": 0.01, "accelerationX": 0.1, "accelerationY": 0.2, "accelerationZ": 0.3, "rotationRateX": 0.4, "rotationRateY": 0.5, "rotationRateZ": 0.6, "gravityX": 0.7, "gravityY": 0.8, "gravityZ": 0.9, "pitch": 1.0, "roll": 1.1, "yaw": 1.2],
        ["time": 0.02, "accelerationX": 0.11, "accelerationY": 0.21, "accelerationZ": 0.31, "rotationRateX": 0.41, "rotationRateY": 0.51, "rotationRateZ": 0.61, "gravityX": 0.71, "gravityY": 0.81, "gravityZ": 0.91, "pitch": 1.01, "roll": 1.11, "yaw": 1.21]
    ])
}
