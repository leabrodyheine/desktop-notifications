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

    /// The box the drawn character actually fills inside its GIF canvas,
    /// as fractions of the canvas: `size` is width/height, `center` is the
    /// character's midpoint. Measured from the union of every frame so the
    /// walk cycle stays put. Lets the view render each character at a
    /// matching on-screen size and seat it on the baseline regardless of
    /// how much empty margin the source GIF carries.
    var contentBox: (size: CGSize, center: CGPoint) {
        switch self {
        case .frog:  return (CGSize(width: 0.732, height: 0.576), CGPoint(x: 0.508, y: 0.512))
        case .chick: return (CGSize(width: 0.401, height: 0.431), CGPoint(x: 0.481, y: 0.507))
        }
    }

    /// Extra downward shift (points) to line the character up with the
    /// reminder bubble.
    var baselineNudge: CGFloat {
        switch self {
        case .chick: return 12
        case .frog: return 0
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
    /// Pixel width / height of a frame.
    var pixelAspect: CGFloat

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
            return PetAnimation(
                frames: [], frameEnd: [], totalDuration: 0, minFrameDelay: 0.1, pixelAspect: 1
            )
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
        let aspect = frames.first.map { CGFloat($0.width) / CGFloat($0.height) } ?? 1
        return PetAnimation(
            frames: frames,
            frameEnd: frameEnd,
            totalDuration: elapsed,
            minFrameDelay: max(minDelay, 0.02),
            pixelAspect: aspect
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

    /// On-screen height of the drawn character — the same for every pet so
    /// they read as one size no matter their source canvas.
    private static let characterHeight: CGFloat = 148
    /// Fixed layout width so the reminder bubble doesn't shift between pets.
    private static let layoutWidth: CGFloat = 208

    var body: some View {
        let animation = PetAnimationCache.animation(for: kind)
        // Flip so the pet faces its direction of travel.
        let flipped = facingLeft != kind.artFacesLeft
        let interval = max(animation.minFrameDelay, 1.0 / 60.0)

        // Blow the frame up so the character (not the whole canvas) is
        // `characterHeight` tall, then slide the character to the middle and
        // clip away the surplus transparent margin.
        let content = kind.contentBox
        let renderHeight = Self.characterHeight / content.size.height
        let renderWidth = renderHeight * animation.pixelAspect
        let characterAspect = animation.pixelAspect * (content.size.width / content.size.height)
        let clipWidth = Self.characterHeight * characterAspect + 4
        let clipHeight = Self.characterHeight + 4
        let shiftX = (0.5 - content.center.x) * renderWidth * (flipped ? -1 : 1)
        let shiftY = (0.5 - content.center.y) * renderHeight

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
                } else {
                    Color.clear
                }
            }
            .frame(width: renderWidth, height: renderHeight)
            .scaleEffect(x: flipped ? -1 : 1, y: 1)
            .offset(x: shiftX, y: shiftY)
        }
        .frame(width: clipWidth, height: clipHeight)
        .clipped()
        .frame(width: Self.layoutWidth, height: Self.characterHeight, alignment: .bottom)
        .offset(y: (isCallingAttention ? -4 : 0) + kind.baselineNudge)
        .allowsHitTesting(false)
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
