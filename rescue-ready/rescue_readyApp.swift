//
//  rescue_readyApp.swift
//  rescue-ready
//
//  Created by Sumangala Rao on 17/10/2026.
//

import SwiftUI
import CoreData

@main
struct rescue_readyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
