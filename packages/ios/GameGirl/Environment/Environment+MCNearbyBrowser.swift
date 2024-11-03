import MultipeerConnectivity
import SwiftUI

struct GameGirlMCNearbyBrowser {
    struct GetPeers {
        let peers: Set<MCPeerID>
        let invite: (MCPeerID, Data?) -> Void
    }
    
    let getPeers: () -> AsyncStream<GetPeers>
}

fileprivate let serviceType = "klolev-gamegirl"
fileprivate let id = MCPeerID(displayName: "GameGirl Serial")

fileprivate func getPeers() -> AsyncStream<GameGirlMCNearbyBrowser.GetPeers> {
    let session = MCSession(peer: id)
    let browser = MCNearbyServiceBrowser(peer: id, serviceType: serviceType)
    let delegate = BrowserDelegate()
    browser.delegate = delegate
    browser.startBrowsingForPeers()
    var iterator = delegate.$peers.values.makeAsyncIterator()
    
    return .init {
        guard let peers = await iterator.next() else {
            return nil
        }
        
        return .init(peers: peers) {
            browser.invitePeer($0, to: session, withContext: $1, timeout: .zero)
        }
    } onCancel: {
        browser.stopBrowsingForPeers()
    }
}

private struct MCNearbyBrowserEnvironmentKey: EnvironmentKey {
    static var defaultValue: GameGirlMCNearbyBrowser {
        .init(getPeers: getPeers)
    }
}

extension EnvironmentValues {
    var nearbyBrowser: GameGirlMCNearbyBrowser {
        get { self[MCNearbyBrowserEnvironmentKey.self] }
        set { self[MCNearbyBrowserEnvironmentKey.self] = newValue }
    }
}

fileprivate class BrowserDelegate: NSObject, MCNearbyServiceBrowserDelegate {
    @Published
    var peers: Set<MCPeerID> = []
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        peers.insert(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        peers.remove(peerID)
    }
}
