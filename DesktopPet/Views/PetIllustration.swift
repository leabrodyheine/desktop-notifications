import CoreGraphics
import ImageIO
import SwiftUI

/// The pets that reminders rotate through. Each ships as an animated GIF in
/// the app bundle; the frames are decoded once and cycled on the GIF's own
/// timing to play its loop.
enum PetKind: String, CaseIterable, Sendable {
    case frog
    case chick

    /// Resource name of the GIF in the bundle.
    var assetName: String {
        switch self {
        case .frog: return "frog"
        case .chick: return "chick"
        }
    }

    /// Direction the artwork faces before any flip.
    var artFacesLeft: Bool {
        switch self {
        case .chick: return true
        case .frog: return false
        }
    }

    /// Per-pet tweak to the on-screen size so tall or small artwork
    /// doesn't read as tiny next to the wider walkers.
    var sizeScale: CGFloat {
        switch self {
        case .chick: return 1.2
        default: return 1
        }
    }
}

/// One decoded GIF: its frames plus the cumulative time each frame ends at.
private struct PetAnimation {
    var frames: [CGImage]
    /// `frameEnd[i]` is the elapsed time (seconds) at which frame `i` finishes.
    var frameEnd: [Double]
    var totalDuration: Double
    var minFrameDelay: Double

    func frameIndex(atElapsed elapsed: Double) -> Int {
        guard totalDuration > 0, !frames.isEmpty else { return 0 }
        let t = elapsed.truncatingRemainder(dividingBy: totalDuration)
        for (i, end) in frameEnd.enumerated() where t < end { return i }
        return frames.count - 1
    }
}

/// Decodes and caches the frames for each pet's GIF.
private enum PetAnimationCache {
    private static var cache: [PetKind: PetAnimation] = [:]

    static func animation(for kind: PetKind) -> PetAnimation {
        if let cached = cache[kind] { return cached }
        let decoded = decode(kind.assetName)
        cache[kind] = decoded
        return decoded
    }

    private static func decode(_ name: String) -> PetAnimation {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "gif"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            return PetAnimation(frames: [], frameEnd: [], totalDuration: 0, minFrameDelay: 0.1)
        }

        let count = CGImageSourceGetCount(source)
        var frames: [CGImage] = []
        var frameEnd: [Double] = []
        var elapsed = 0.0
        var minDelay = Double.greatestFiniteMagnitude

        for index in 0..<count {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let delay = frameDelay(source, index)
            frames.append(frame)
            elapsed += delay
            frameEnd.append(elapsed)
            minDelay = min(minDelay, delay)
        }

        if !minDelay.isFinite { minDelay = 0.1 }
        return PetAnimation(
            frames: frames,
            frameEnd: frameEnd,
            totalDuration: elapsed,
            minFrameDelay: max(minDelay, 0.02)
        )
    }

    /// GIF per-frame delay in seconds, clamped to a sane floor.
    private static func frameDelay(_ source: CGImageSource, _ index: Int) -> Double {
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let unclamped = gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif?[kCGImagePropertyGIFDelayTime] as? Double
        let delay = unclamped ?? clamped ?? 0.1
        return delay < 0.011 ? 0.1 : delay
    }
}

struct PetIllustration: View {
    var kind: PetKind
    var isCallingAttention: Bool = false
    /// True when the pet is travelling right-to-left across the screen.
    var facingLeft: Bool = false

    var body: some View {
        let animation = PetAnimationCache.animation(for: kind)
        // Flip so the pet faces its direction of travel.
        let flipped = facingLeft != kind.artFacesLeft
        let interval = max(animation.minFrameDelay, 1.0 / 60.0)

        TimelineView(.animation(minimumInterval: interval, paused: isCallingAttention)) { timeline in
            let index: Int = {
                guard !animation.frames.isEmpty else { return 0 }
                if isCallingAttention { return 0 } // settle on a neutral pose while centred
                return animation.frameIndex(atElapsed: timeline.date.timeIntervalSinceReferenceDate)
            }()

            Group {
                if animation.frames.indices.contains(index) {
                    Image(decorative: animation.frames[index], scale: 1, orientation: .up)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.clear
                }
            }
            .scaleEffect(x: flipped ? -1 : 1, y: 1)
        }
        .frame(width: 152 * kind.sizeScale, height: 140 * kind.sizeScale)
        .offset(y: isCallingAttention ? -4 : 0)
        .animation(.spring(response: 0.34, dampingFraction: 0.55), value: isCallingAttention)
        .accessibilityLabel("Pet")
    }
}

#Preview {
    HStack(spacing: 8) {
        PetIllustration(kind: .frog)
        PetIllustration(kind: .chick, facingLeft: true)
    }
    .padding()
    .background(Color(white: 0.15))
}
