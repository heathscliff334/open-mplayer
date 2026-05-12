import SwiftUI
import AVKit

struct VideoPlayerLayerView: NSViewRepresentable {
    let player: AVPlayer
    var onLayerReady: ((AVPlayerLayer) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.wantsLayer = true
        view.layer = playerLayer

        // Notify when layer is ready
        DispatchQueue.main.async {
            onLayerReady?(playerLayer)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVPlayerLayer {
            layer.player = player
        }
    }
}
