import MultipeerConnectivity
import SwiftUI

struct RustyboyMCNearbyBrowser {
    let getPeers: () -> AsyncStream<Set<MCPeerID>>
}

fileprivate let serviceType = "klolev-rustyboy"
fileprivate let id = MCPeerID(displayName: "Rustyboy Serial")

fileprivate func getPeers() -> AsyncStream<Set<MCPeerID>> {
    let browser = MCNearbyServiceBrowser(peer: id, serviceType: serviceType)
    let delegate = BrowserDelegate()
    browser.delegate = delegate
    browser.startBrowsingForPeers()
    var iterator = delegate.$peers.values.makeAsyncIterator()
    
    return .init {
        await iterator.next()
    } onCancel: {
        browser.stopBrowsingForPeers()
    }
}

private struct MCNearbyBrowserEnvironmentKey: EnvironmentKey {
    static var defaultValue: RustyboyMCNearbyBrowser {
        .init { getPeers() }
    }
}

extension EnvironmentValues {
    var nearbyBrowser: RustyboyMCNearbyBrowser {
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
