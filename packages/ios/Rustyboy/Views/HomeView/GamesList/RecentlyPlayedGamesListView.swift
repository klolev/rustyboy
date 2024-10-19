import SwiftUI
import SwiftData
import Slingshot

struct RecentlyPlayedGamesListView: View {
    enum ViewState {
        struct AlphabeticalState {
            @State
            var selectedLetter: Character = "A"
            
            func availableLetters(in games: [Game]) -> Set<Character> {
                Set(games.compactMap(\.name.first))
            }
            
            func first(gameStartingWith character: Character,
                       in games: [Game]) -> Game? {
                games.first(where: { $0.name.first == character })
            }
        }
        
        struct RecentlyPlayedState {
            let groupGames: ([Game]) -> [(String, [Game])]
        }
        
        case alphabetical(AlphabeticalState)
        case recentlyPlayed(RecentlyPlayedState)
        
        var sortDescriptors: [SortDescriptor<Game>] {
            switch self {
            case .alphabetical:
                [.init(\.name, order: .forward)]
            case .recentlyPlayed:
                [.init(\.lastPlayedDate, order: .reverse),
                 .init(\.importDate, order: .reverse)]
            }
        }
        
        var alphabeticalState: AlphabeticalState? {
            switch self {
            case .alphabetical(let alphabeticalState):
                alphabeticalState
            case .recentlyPlayed:
                nil
            }
        }
        
        func games(from source: [Game]) -> Either<[(String, [Game])], [Game]> {
            switch self {
            case .alphabetical:
                .right(source)
            case .recentlyPlayed(let recentlyPlayedState):
                .left(recentlyPlayedState.groupGames(source))
            }
        }
    }
    
    let state: ViewState
    let didSelectGame: (Game) -> Void
    
    @Query
    private var sortedGames: [Game]
    
    init(state: ViewState,
         didSelectGame: @escaping (Game) -> Void) {
        self.state = state
        self.didSelectGame = didSelectGame
        self._sortedGames = .init(sort: state.sortDescriptors)
    }
    
    @ViewBuilder
    private var gameCells: some View {
        switch state.games(from: sortedGames) {
        case .right(let flat):
            ForEach(flat, id: \.id) { game in
                GameListCellView(name: game.name, didSelect: { didSelectGame(game) })
                    .id(game.id)
            }
        case .left(let grouped):
            ForEach(grouped, id: \.0) { section in
                Section {
                    ForEach(section.1) { game in
                        GameListCellView(name: game.name, didSelect: { didSelectGame(game) })
                    }
                } header: {
                    HStack {
                        Text(section.0.localized)
                            .font(.semiBold(20))
                        
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .padding(.top, 8)
                }
                .headerProminence(.standard)
                .id(section.0)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollViewReader { scrollViewReader in
                ScrollView {
                    LazyVGrid(columns: [.init(), .init()], spacing: 24, pinnedViews: .sectionHeaders) {
                        gameCells
                    }
                    .padding(.horizontal, 16)
                    .ifLet(state.alphabeticalState) { view, state in
                        view.onChange(of: state.selectedLetter) { _, newValue in
                            guard let game = state.first(gameStartingWith: newValue, in: sortedGames) else { return }
                            scrollViewReader.scrollTo(game.id, anchor: .center)
                        }.padding(.top, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            if case .alphabetical(let alphabeticalState) = state {
                AlphabetScrollIndicatorView(selection: alphabeticalState.$selectedLetter,
                                            availableLetters: alphabeticalState.availableLetters(in: sortedGames))
            }
        }
    }
}
