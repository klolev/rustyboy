import Foundation
import SQLite

public struct OpenVGDB {
    enum ConnectionError: Error {
        case fileNotFound
    }
    
    public struct Release {
        public let name: String
        public let cover: URL?
        public let description: String
        public let developer: String
        public let publisher: String
        public let genre: String
        public let releaseDate: Date?
        public let header: String
        public let hash: String
    }
    
    public init() {}
    
    private func connection() throws -> Connection {
        guard let path = Bundle.module.path(forResource: "openvgdb.sqlite", ofType: nil) else {
            throw ConnectionError.fileNotFound
        }
        return try .init(path)
    }
    
    public func list(matchesForGameNamed name: String,
                     withHeader header: String,
                     andHash hash: String) throws -> [Release] {
        let connection = try connection()
        let statement = try connection.prepareRowIterator("""
            select
                releases.releaseTitleName,
                releases.releaseCoverFront,
                releases.releaseDescription,
                releases.releaseDeveloper, 
                releases.releasePublisher,
                releases.releaseGenre,
                releases.releaseDate,
                roms.romHeader,
                roms.romHashMD5
            from roms
            full outer join releases on releases.romID = roms.romID
            where roms.romFileName like ?
                or roms.romHeader = ?
                or releases.releaseTitleName like ?
                or roms.romHashMD5 = ?
        """, bindings: "%\(name)%", header.uppercased(), "%\(name)%", hash.uppercased())
        
        return try statement.compactMap {
            guard let name: String = try? $0.get(.init("releaseTitleName")) else {
                return nil
            }
            
            let cover: String? = try? $0.get(.init("releaseCoverFront"))
            let coverURL = cover.flatMap(URL.init(string:))
            let description: String? = try? $0.get(.init("releaseDescription"))
            let developer: String? = try? $0.get(.init("releaseDeveloper"))
            let publisher: String? = try? $0.get(.init("releasePublisher"))
            let genre: String? = try? $0.get(.init("releaseGenre"))
            let header: String? = try? $0.get(.init("romHeader"))
            let hash: String? = try? $0.get(.init("romHashMD5"))

            return Release(name: name,
                           cover: coverURL,
                           description: description ?? "",
                           developer: developer ?? "",
                           publisher: publisher ?? "",
                           genre: genre ?? "",
                           releaseDate: nil,
                           header: header ?? "",
                           hash: hash ?? "")
        }
        .sorted { left, right in
            left.header == header || left.hash == hash
        }
    }
}
