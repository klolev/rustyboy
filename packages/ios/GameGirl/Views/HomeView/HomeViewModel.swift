import Foundation
import CryptoKit
import Slingshot
import GameGirlCoreBindings
import OrderedCollections
import OpenVGDB

struct HomeViewModel {
    let now: () -> Date
    
    enum ImportError: Error {
        case securityScopeError
        case ioError(Error)
        case invalidROM(CartridgeMetadataError)
        case fileImporterError(Error)
    }
    
    func didSelect(game: Game) {
        game.lastPlayedDate = now()
    }
    
    func group(games: [Game]) -> [(String, [Game])] {
        let now = now()
        let calendar = Calendar.current
        guard let today = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let lastWeek = calendar.date(byAdding: .day, value: -7, to: thisWeek),
              let thisMonth = calendar.dateInterval(of: .month, for: today)?.start,
              let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth),
              let lastThreeMonths = calendar.date(byAdding: .month, value: -2, to: lastMonth),
              let lastSixMonths = calendar.date(byAdding: .month, value: -3, to: lastThreeMonths),
              let thisYear = calendar.dateInterval(of: .year, for: today)?.start else { return [] }
        
        let staticIntervals = [(id: "today", condition: today),
                               (id: "yesterday", condition: yesterday),
                               (id: "this_week", condition: thisWeek),
                               (id: "last_week", condition: lastWeek),
                               (id: "this_month", condition: thisMonth),
                               (id: "last_month", condition: lastMonth),
                               (id: "last_three_months", condition: lastThreeMonths),
                               (id: "last_six_months", condition: lastSixMonths),
                               (id: "this_year", condition: thisYear)]
            .reduce { (acc: [(id: String, condition: Date)], x) in
                guard let last = acc.last else {
                    return [x]
                }
                
                if last.1 < x.1 {
                    return acc
                } else {
                    return acc + [x]
                }
            }
        
        let groups = (1...)
            .lazy
            .compactMap { calendar.date(byAdding: .year, value: -$0, to: thisYear) }
            .map { (id: "\(calendar.component(.year, from: $0))", condition: $0) }
            .prefix(by: staticIntervals)
        
        return groupc(orderedElements: games,
                      inOrderedGroups: groups,
                      byEvaluating: { (game: Game, intervalStart: Date) in
            (game.lastPlayedDate ?? game.importDate) >= intervalStart
        })
        .asArray
    }
    
    private func get(matchingReleasesForGameNamed name: String,
                     withHeader header: Data,
                     andHash hash: String) throws -> OpenVGDB.Release? {
        try OpenVGDB()
            .list(matchesForGameNamed: name.split(separator: ".").first.map(String.init) ?? name,
                  withHeader: header.map { String(format: "%02hhx", $0) }.joined(),
                  andHash: hash)
            .first
    }
    
    private func fetch(imageAtURL url: URL) async -> Data? {
        do {
            return try await URLSession.shared.data(from: url).0
        } catch {
            print("Error fetching artwork at \(url)", error)
            return nil
        }
    }
    
    func importGames(atURLs urls: [URL]) async -> Result<[Game], ImportError> {
        let importDate = now()
        return await urls
        .traverse { url -> Promise<Result<Game, ImportError>> in
            Promise {
                let name = url.lastPathComponent
                guard url.startAccessingSecurityScopedResource() else {
                    return Result.failure(ImportError.securityScopeError)
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let data = try Data(contentsOf: url)
                    let cartridge = try GameGirlCartridge(buffer: data)
                    let metadata = cartridge.getMetadata()
                    let hash = Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
                    let release = try get(matchingReleasesForGameNamed: name,
                                          withHeader: metadata.header,
                                          andHash: hash)
                    let image: Data? = if let cover = release?.cover {
                        await fetch(imageAtURL: cover)
                    } else { nil }
                    
                    return .success(Game(name: release?.name ?? name,
                                         rom: data,
                                         importDate: importDate,
                                         headerMetadata: metadata,
                                         image: image,
                                         releaseDescription: release?.description ?? .zero,
                                         developer: release?.developer ?? .zero,
                                         publisher: release?.publisher ?? .zero,
                                         genre: release?.genre ?? .zero,
                                         releaseDate: release?.releaseDate))
                } catch {
                    if let error = error as? CartridgeMetadataError {
                        return .failure(.invalidROM(error))
                    } else {
                        return .failure(.ioError(error))
                    }
                }
            }
        }
        .map(\.sequenced)
        .value
    }
}
