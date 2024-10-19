import SwiftUI
import SwiftData

@main
struct RustyboyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self,
            Savestate.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @Environment(\.openWindow)
    private var openWindow
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var selectedGame: Game?

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            HomeView(viewModel: .init(now: Date.init),
                     didSelectGame: { openWindow(value: $0.id) })
            #else
            HomeView(viewModel: .init(now: Date.init),
                     didSelectGame: { selectedGame = $0 })
            .fullScreenCover(item: $selectedGame) { game in
                GameView(viewModel: .init(game: game), dismiss: { selectedGame = nil })
            }
            #endif
        }
        .modelContainer(sharedModelContainer)
        
        #if os(macOS)
        WindowGroup("Game", id: "game", for: Game.ID.self) { selectedGameID in
            if let id = selectedGameID.wrappedValue,
               let game = sharedModelContainer.mainContext.model(for: id) as? Game {
                GameView(viewModel: .init(game: game), dismiss: { dismiss() })
            } else {
                Text("oop")
            }
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}
