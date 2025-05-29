import SwiftUI
import SwiftData

@main
struct GameGirlApp: App {
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
    
    @Environment(\.self)
    private var environment
    
    @AppStorage("gamepadStyle")
    private var gamepadStyleName: String?
    
    @AppStorage("lcdFilter")
    private var isLCDFilterEnabled: Bool = false
    
    private var gamepadStyle: Binding<GamepadStyle> {
        $gamepadStyleName.invmap({ rawValue in
            rawValue.flatMap(GamepadStyle.init(rawValue:)) ?? .gbcRed
        }, {
            $0.rawValue(in: environment)
        })
    }

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
        .environment(\.gamepadStyle, gamepadStyle)
        .environment(\.screenFilter, $isLCDFilterEnabled)
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
        .environment(\.gamepadStyle, gamepadStyle)
        .environment(\.screenFilter, $isLCDFilterEnabled)
        .modelContainer(sharedModelContainer)
        #endif
    }
}
