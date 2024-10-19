import Foundation
import RustyboyCoreBindings
#if canImport(UIKit)
import UIKit
#endif

@Observable
class GameViewModel {
    let game: Game
    var pauseScreen: Data?
    let now: () -> Date
    var gameboy: RustyboyGameboy?
    var heldButtons: UInt8 = 0
    
#if canImport(UIKit)
    private var pushDownGenerator: UIImpactFeedbackGenerator
    private var releaseGenerator: UIImpactFeedbackGenerator
#endif
    
    init(game: Game, now: @escaping () -> Date = Date.init) {
        self.game = game
        self.now = now
#if canImport(UIKit)
        self.pushDownGenerator = .init(style: .rigid)
        self.releaseGenerator = .init(style: .soft)
#endif
    }
    
    enum GameStartError: Error {
        case initializationError(Error)
        case lastSavestateLoadError(Error)
    }
    
    func start() -> Result<RustyboyGameboy, GameStartError> {
        do {
            gameboy = try RustyboyGameboy(buffer: game.rom)
        } catch {
            return .failure(.initializationError(error))
        }
        
        if let latestSavestate = game.savestates.max(by: \.timestamp) {
            do {
                try gameboy?.loadSavestate(buffer: latestSavestate.data)
            } catch {
                return .failure(.lastSavestateLoadError(error))
            }
        }
#if canImport(UIKit)
        pushDownGenerator.prepare()
        releaseGenerator.prepare()
#endif
        return .success(gameboy!)
    }
    
    func renderer(withGameboy gameboy: RustyboyGameboy) -> () -> Data {
        { [weak self] in
            guard let self else { return .init() }
            if let pauseScreen { return pauseScreen }
            
            return gameboy.getFrame()
        }
    }
    
    func load(savestate: Savestate, withGameboy gameboy: RustyboyGameboy) -> Result<(), LoadSavestateError> {
        do {
            try gameboy.loadSavestate(buffer: savestate.data)
            pauseScreen = nil
            return .success(())
        } catch {
            if let error = error as? LoadSavestateError {
                return .failure(error)
            } else {
                return .failure(.InvalidSavestate(message: "Unknown error"))
            }
        }
    }
    
    func reset(gameboy: RustyboyGameboy) {
        gameboy.reset()
        pauseScreen = nil
    }
    
    func save(gameboy: RustyboyGameboy) -> Savestate? {
        guard let pauseScreen else { return nil }
        
        return Savestate(timestamp: now(),
                         game: game,
                         image: pauseScreen,
                         data: gameboy.dumpSavestate())
    }
    
    func pause(withGameboy gameboy: RustyboyGameboy) {
        guard pauseScreen == nil else { return }
        pauseScreen = gameboy.runToVblank(input: .init(heldButtons: heldButtons))
    }
    
    func resume() {
        pauseScreen = nil
    }
    
    func didChange(direction: DirectionalPadView.Direction?) {
        heldButtons = (heldButtons & 0b00001111) | (direction?.rustValue ?? 0)
        
#if canImport(UIKit)
        if direction != nil {
            pushDownGenerator.impactOccurred()
        } else {
            releaseGenerator.impactOccurred(intensity: 0.7)
        }
#endif
    }
    
    func didChange(heldButtons: GamepadView.ButtonSet) {
        let oldHeldButtons = self.heldButtons
        self.heldButtons = (self.heldButtons & 0b11110000) | heldButtons.rawValue
        
#if canImport(UIKit)
        if (oldHeldButtons ^ self.heldButtons) & oldHeldButtons != 0 {
            releaseGenerator.impactOccurred(intensity: 0.7)
            
        } else if (oldHeldButtons ^ self.heldButtons) & (~oldHeldButtons) != 0 {
            pushDownGenerator.impactOccurred()
        }
#endif
    }
}

fileprivate extension DirectionalPadView.Direction {
    var rustValue: UInt8 {
        switch self {
        case .right:
            return 16
        case .up:
            return 64
        case .left:
            return 32
        case .down:
            return 128
        }
    }
}
