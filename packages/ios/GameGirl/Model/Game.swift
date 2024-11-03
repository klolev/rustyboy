import Foundation
import SwiftData
import GameGirlCoreBindings

@Model
final class Game {
    var name: String
    var importDate: Date
    var lastPlayedDate: Date?
    var headerMetadata: HeaderMetadata
    var releaseDescription: String
    var developer: String
    var publisher: String
    var genre: String
    var releaseDate: Date?

    @Attribute(.externalStorage)
    var image: Data?
    
    @Attribute(.externalStorage)
    var rom: Data
    
    @Relationship(deleteRule: .cascade, inverse: \Savestate.game)
    var savestates: [Savestate]
    
    struct HeaderMetadata: Codable {
        var header: Data
        var title: String
        var manufacturerCode: String?
        var cgbFlag: CgbFlag?
        var newLicenseeCode: String?
        var sgbEnhanced: Bool
        var capabilities: [CartridgeCapability]
        var romSize: UInt64
        var ramSize: UInt64
        var destinationIsJapan: Bool
        var oldLicenseeCode: UInt8?
        var version: UInt8
        var headerChecksum: UInt8
        var globalChecksum: UInt8
    }
    
    init(name: String,
         rom: Data,
         importDate: Date,
         lastPlayedDate: Date? = nil,
         headerMetadata: CartridgeMetadata? = nil,
         image: Data? = nil,
         releaseDescription: String = .zero,
         developer: String = .zero,
         publisher: String = .zero,
         genre: String = .zero,
         releaseDate: Date? = nil,
         savestates: [Savestate] = []) {
        self.name = name
        self.rom = rom
        self.headerMetadata = headerMetadata.map { .init(from: $0) } ??
            .init(header: .init(),
                  title: .zero,
                  manufacturerCode: nil,
                  cgbFlag: nil,
                  newLicenseeCode: nil,
                  sgbEnhanced: false,
                  capabilities: [],
                  romSize: 0,
                  ramSize: 0,
                  destinationIsJapan: false,
                  oldLicenseeCode: nil,
                  version: 0,
                  headerChecksum: 0,
                  globalChecksum: 0)
        self.importDate = importDate
        self.lastPlayedDate = lastPlayedDate
        self.savestates = savestates
        self.image = image
        self.releaseDescription = releaseDescription
        self.developer = developer
        self.publisher = publisher
        self.genre = genre
        self.releaseDate = releaseDate
    }
}

extension Game.HeaderMetadata {
    init(from metadata: CartridgeMetadata) {
        self.header = metadata.header
        self.title = metadata.title
        self.manufacturerCode = metadata.manufacturerCode
        self.cgbFlag = metadata.cgbFlag
        self.newLicenseeCode = metadata.newLicenseeCode
        self.sgbEnhanced = metadata.sgbEnhanced
        self.capabilities = metadata.capabilities
        self.romSize = metadata.romSize
        self.ramSize = metadata.ramSize
        self.destinationIsJapan = metadata.destination == .japanese
        self.oldLicenseeCode = metadata.oldLicenseeCode
        self.version = metadata.version
        self.headerChecksum = metadata.headerChecksum
        self.globalChecksum = metadata.globalChecksum
    }
}

extension CgbFlag: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Bool.self)
        self = value ? .cgbOnly : .supportsCgb
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .cgbOnly:
            try container.encode(true)
        case .supportsCgb:
            try container.encode(false)
        }
    }
}

extension CartridgeCapability: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self = switch value {
        case 0: .rom
        case 1: .mbc1
        case 2: .mbc2
        case 3: .mbc3
        case 4: .mbc4
        case 5: .mbc5
        case 6: .ram
        case 7: .battery
        case 8: .timer
        case 9: .mmm01
        case 10: .rumble
        case 11: .pocketCamera
        case 12: .bandaiTama5
        case 13: .huC1
        default: .huC3
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = switch self {
        case .rom: 0
        case .mbc1: 1
        case .mbc2: 2
        case .mbc3: 3
        case .mbc4: 4
        case .mbc5: 5
        case .ram: 6
        case .battery: 7
        case .timer: 8
        case .mmm01: 9
        case .rumble: 10
        case .pocketCamera: 11
        case .bandaiTama5: 12
        case .huC1: 13
        case .huC3: 14
        }
        
        try container.encode(value)
    }
}
