import SwiftUI
import SwiftData

@main
struct LiquidLedgerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Bill.self, Account.self, Transfer.self])
    }
}