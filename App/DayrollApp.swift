import SwiftUI

@main
struct DayrollApp: App {
    @State private var pro = ProStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(pro)
                .task {
                    #if DEBUG
                    if CommandLine.arguments.contains("-seedDemo") {
                        DataStore.seedDemo(days: 400)
                    }
                    #endif
                    await pro.load()
                    await pro.listenForTransactions()
                }
        }
        .modelContainer(DataStore.container)
    }
}
