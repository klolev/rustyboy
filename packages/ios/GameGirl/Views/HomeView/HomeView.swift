import SwiftUI
import SwiftData
import Slingshot

struct HomeView: View {
    @Environment(\.modelContext) 
    private var modelContext
    
    @Query(sort: [SortDescriptor(\Game.lastPlayedDate), SortDescriptor(\Game.importDate)])
    private var games: [Game]
    
    @State
    private var isShowingFilePicker = false
    
    private let viewModel: HomeViewModel
    private let didSelectGame: (Game) -> Void
    
    @State
    private var isLoading: Bool = false
    
    init(viewModel: HomeViewModel,
         didSelectGame: @escaping (Game) -> Void) {
        self.viewModel = viewModel
        self.didSelectGame = didSelectGame
    }
    
    private func didSelectFiles(withResult result: Result<[URL], Error>) {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let urls = try result.get()
                let newGames = try await viewModel.importGames(atURLs: urls).get()
                
                withAnimation {
                    for game in newGames {
                        modelContext.insert(game)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func didSelect(game: Game) {
        viewModel.didSelect(game: game)
        didSelectGame(game)
    }

    var body: some View {
        Group {
            if games.isEmpty {
                HomeEmptyStateView(didPressAddGame: { isShowingFilePicker = true })
            } else {
                GamesListView(didSelectGame: didSelect(game:),
                              didTapAddGame: { isShowingFilePicker = true },
                              groupGames: viewModel.group(games:))
            }
        }
        .animation(.default, value: isLoading)
        .if(isLoading) {
            $0.overlay {
                ZStack {
                    ProgressView()
                    Color.black.opacity(0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
        }
        .fileImporter(isPresented: $isShowingFilePicker,
                      allowedContentTypes: [.data],
                      allowsMultipleSelection: true,
                      onCompletion: didSelectFiles(withResult:))
    }
}

#Preview {
    HomeView(viewModel: .init(now: Date.init), didSelectGame: { _ in })
        .modelContainer(for: [Game.self, Savestate.self], inMemory: true)
}
