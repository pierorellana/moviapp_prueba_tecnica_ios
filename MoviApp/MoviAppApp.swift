//
//  MoviAppApp.swift
//  MoviApp
//
//  Created by Jorge on 16/6/26.
//

import Foundation
import SwiftUI

@main
struct MoviAppApp: App {
    var body: some Scene {
        WindowGroup {
            if isRunningUnitTests {
                Text("Running tests")
            } else {
                ContentView()
            }
        }
    }

    private var isRunningUnitTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
