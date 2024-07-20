//
//  DataController.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/19.
//


import CoreData
import Foundation

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "SensorDataModel")
    
    init() {
        container.loadPersistentStores { description, error in
            
            if let error = error {
                print("Core data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
