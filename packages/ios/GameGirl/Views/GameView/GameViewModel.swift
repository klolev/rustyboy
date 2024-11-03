import AVFAudio
import Foundation
import GameGirlCoreBindings

#if canImport(UIKit)
import UIKit
#endif

@Observable
class GameViewModel {
    let game: Game
    var pauseScreen: Data?
    let now: () -> Date
    var gameboy: GameGirlGameboy?
    private let engine: AVAudioEngine
    private var audioNode: AVAudioSourceNode?
    private let format: AVAudioFormat
    var heldButtons: UInt8 = 0

    #if FALSE
    var audioDebugging: AudioDebugging?
    #endif

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
        format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        engine = .init()
    }

    enum GameStartError: Error {
        case initializationError(Error)
        case lastSavestateLoadError(Error)
    }

    func start() -> Result<GameGirlGameboy, GameStartError> {
        do {
            gameboy = try GameGirlGameboy(buffer: game.rom)
            let audioNode = AVAudioSourceNode(format: format,
                                              renderBlock: audioRender(isSilence:timestamp:frameCount:outputData:))
            self.audioNode = audioNode
            engine.attach(audioNode)
            engine.connect(audioNode, to: engine.mainMixerNode, format: format)
            try engine.start()
            engine.prepare()
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

    //    func renderer(withGameboy gameboy: GameGirlGameboy) -> () -> Data {
    //        { [weak self] in
    //            guard let self else { return .init() }
    //            if let pauseScreen { return pauseScreen }
    //
    //            return gameboy.getFrame()
    //        }
    //    }
    
    private var audioBuffer: [AudioSample] = []
    private var audioBufferBuffer: [AudioSample] = []
    
    private func audioRender(isSilence: UnsafeMutablePointer<ObjCBool>,
                             timestamp: UnsafePointer<AudioTimeStamp>,
                             frameCount: AVAudioFrameCount,
                             outputData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        if !audioBufferBuffer.isEmpty {
            audioBuffer.append(contentsOf: audioBufferBuffer)
            audioBufferBuffer.removeAll(keepingCapacity: true)
        }
        
        let dataCount = min(frameCount.count, audioBuffer.count)
        let outputBuffers = UnsafeMutableAudioBufferListPointer(outputData)
        let leftChannel = UnsafeMutableBufferPointer<Float>(outputBuffers[0])
        let rightChannel = UnsafeMutableBufferPointer<Float>(outputBuffers[1])
        for i in 0..<dataCount {
            leftChannel[i] = Float(audioBuffer[i].left)
            rightChannel[i] = Float(audioBuffer[i].right)
        }
        for i in dataCount..<frameCount.count {
            leftChannel[i] = 0
            rightChannel[i] = 0
        }
        audioBuffer.removeFirst(dataCount)
        
        return 0
    }

    public func update(deltaTime: Double) -> Data? {
        guard let gameboy else { return nil }
        let result = gameboy.update(input: .init(heldButtons: heldButtons), deltaTime: deltaTime)

        if let audioSamples = result.audioSamples {
            audioBufferBuffer.append(contentsOf: audioSamples)
        }

        #if FALSE
            audioDebugging = gameboy.getAudioDebugging()
        #endif

        return result.frame
    }

    func load(savestate: Savestate, withGameboy gameboy: GameGirlGameboy) -> Result<(), LoadSavestateError> {
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

    func reset(gameboy: GameGirlGameboy) {
        gameboy.reset()
        pauseScreen = nil
    }

    func save(gameboy: GameGirlGameboy) -> Savestate? {
        guard let pauseScreen else { return nil }

        return Savestate(
            timestamp: now(),
            game: game,
            image: pauseScreen,
            data: gameboy.dumpSavestate())
    }

    func pause(withGameboy gameboy: GameGirlGameboy) {
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

extension DirectionalPadView.Direction {
    fileprivate var rustValue: UInt8 {
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
