import Foundation
import SwiftUI

/// The placeholder pets that reminders rotate through. Each is drawn with
/// vector primitives in a soft, minimal sticker style so artwork can be
/// swapped later without touching calendar or presentation logic.
enum PetKind: String, CaseIterable, Sendable {
    case calicoCat
    case greyTabbyCat
    case orangeCat
    case hamster
}

struct PetPalette {
    var fur: Color
    var patch: Color
    var belly: Color
    var secondaryPatch: Color

    /// Warm, soft outline colour — never pure black.
    static let ink = Color(red: 0.34, green: 0.29, blue: 0.27)
    static let blush = Color(red: 0.93, green: 0.71, blue: 0.70)
    static let earPink = Color(red: 0.95, green: 0.82, blue: 0.82)
    static let noseTint = Color(red: 0.86, green: 0.60, blue: 0.58)

    static let calico = PetPalette(
        fur: Color(red: 0.96, green: 0.93, blue: 0.87),
        patch: Color(red: 0.90, green: 0.71, blue: 0.52),
        belly: Color(red: 0.99, green: 0.97, blue: 0.93),
        secondaryPatch: Color(red: 0.75, green: 0.74, blue: 0.73)
    )
    static let greyTabby = PetPalette(
        fur: Color(red: 0.80, green: 0.80, blue: 0.82),
        patch: Color(red: 0.67, green: 0.67, blue: 0.70),
        belly: Color(red: 0.93, green: 0.93, blue: 0.94),
        secondaryPatch: Color(red: 0.67, green: 0.67, blue: 0.70)
    )
    static let orange = PetPalette(
        fur: Color(red: 0.93, green: 0.72, blue: 0.50),
        patch: Color(red: 0.84, green: 0.61, blue: 0.39),
        belly: Color(red: 0.98, green: 0.92, blue: 0.83),
        secondaryPatch: Color(red: 0.84, green: 0.61, blue: 0.39)
    )
    static let hamster = PetPalette(
        fur: Color(red: 0.91, green: 0.83, blue: 0.68),
        patch: Color(red: 0.84, green: 0.74, blue: 0.58),
        belly: Color(red: 0.99, green: 0.96, blue: 0.90),
        secondaryPatch: Color(red: 0.84, green: 0.74, blue: 0.58)
    )
}

struct PetIllustration: View {
    var kind: PetKind
    var isCallingAttention: Bool = false

    private static let designSize = CGSize(width: 120, height: 128)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isCallingAttention)) { timeline in
            Canvas { context, size in
                context.transform = CGAffineTransform(
                    scaleX: size.width / Self.designSize.width,
                    y: size.height / Self.designSize.height
                )
                let time = timeline.date.timeIntervalSinceReferenceDate

                switch kind {
                case .calicoCat:
                    drawSittingCat(context, palette: .calico)
                case .greyTabbyCat:
                    drawLoafCat(context, palette: .greyTabby)
                case .orangeCat:
                    let wiggle = isCallingAttention ? CGFloat(sin(time * 7)) * 0.3 : 0
                    drawPeekingCat(context, palette: .orange, wave: 0.06 + wiggle)
                case .hamster:
                    drawHamster(context, palette: .hamster)
                }
            }
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height)
        .scaleEffect(isCallingAttention ? 1.04 : 1.0, anchor: .bottom)
        .offset(y: isCallingAttention ? -3 : 0)
        .animation(.easeInOut(duration: 0.36).repeatForever(autoreverses: true), value: isCallingAttention)
        .overlay(alignment: .topTrailing) {
            if isCallingAttention {
                Text("!")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(Circle().fill(Color(red: 0.95, green: 0.78, blue: 0.35)))
                    .overlay(Circle().stroke(PetPalette.ink, lineWidth: 1.5))
                    .offset(x: -6, y: 2)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.62), value: isCallingAttention)
    }
}

// MARK: - Geometry helpers

private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
}

private func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
}

private func triangle(_ apex: CGPoint, _ left: CGPoint, _ right: CGPoint) -> Path {
    var path = Path()
    path.move(to: apex)
    path.addLine(to: right)
    path.addLine(to: left)
    path.closeSubpath()
    return path
}

private func segment(_ a: CGPoint, _ b: CGPoint) -> Path {
    var path = Path()
    path.move(to: a)
    path.addLine(to: b)
    return path
}

/// A shallow downward-bulging curve, for closed "sleepy" eyes and tucked paws.
private func downCurve(_ centerX: CGFloat, _ centerY: CGFloat, _ width: CGFloat, _ depth: CGFloat) -> Path {
    var path = Path()
    path.move(to: p(centerX - width / 2, centerY))
    path.addQuadCurve(to: p(centerX + width / 2, centerY), control: p(centerX, centerY + depth))
    return path
}

private func chevron(_ centerX: CGFloat, _ centerY: CGFloat, _ width: CGFloat, _ height: CGFloat) -> Path {
    var path = Path()
    path.move(to: p(centerX - width / 2, centerY + height / 2))
    path.addLine(to: p(centerX, centerY - height / 2))
    path.addLine(to: p(centerX + width / 2, centerY + height / 2))
    return path
}

private func tinyMouth(_ centerX: CGFloat, _ centerY: CGFloat) -> Path {
    var path = Path()
    path.move(to: p(centerX - 4, centerY))
    path.addQuadCurve(to: p(centerX, centerY + 2.6), control: p(centerX - 2, centerY + 2.6))
    path.addQuadCurve(to: p(centerX + 4, centerY), control: p(centerX + 2, centerY + 2.6))
    return path
}

private func rotate(_ path: Path, _ radians: CGFloat, around center: CGPoint) -> Path {
    path.applying(
        CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: radians)
            .translatedBy(x: -center.x, y: -center.y)
    )
}

// MARK: - Drawing helpers

private let outlineStyle = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)

private func shape(_ context: GraphicsContext, _ path: Path, _ fill: Color, outline: Bool = true, lineWidth: CGFloat = 2) {
    context.fill(path, with: .color(fill))
    if outline {
        context.stroke(path, with: .color(PetPalette.ink), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

private func line(_ context: GraphicsContext, _ path: Path, _ color: Color = PetPalette.ink, lineWidth: CGFloat = 1.8) {
    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
}

private func dotEyes(_ context: GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, size: CGFloat = 6.5) {
    context.fill(oval(leftX - size / 2, y - size / 2, size, size * 1.15), with: .color(PetPalette.ink))
    context.fill(oval(rightX - size / 2, y - size / 2, size, size * 1.15), with: .color(PetPalette.ink))
}

private func softBlush(_ context: GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, width: CGFloat = 11) {
    context.fill(oval(leftX - width / 2, y - 3.5, width, 7), with: .color(PetPalette.blush.opacity(0.35)))
    context.fill(oval(rightX - width / 2, y - 3.5, width, 7), with: .color(PetPalette.blush.opacity(0.35)))
}

private func nose(_ context: GraphicsContext, _ centerX: CGFloat, _ y: CGFloat, width: CGFloat = 5) {
    var path = Path()
    path.move(to: p(centerX - width / 2, y))
    path.addLine(to: p(centerX + width / 2, y))
    path.addQuadCurve(to: p(centerX, y + width * 0.75), control: p(centerX, y + width * 0.75))
    path.closeSubpath()
    context.fill(path, with: .color(PetPalette.noseTint))
}

// MARK: - Pets

/// A smooth pear silhouette — head and body share one outline, like the
/// reference sitting-cat stickers.
private func sittingCatSilhouette() -> Path {
    var path = Path()
    path.move(to: p(60, 8))
    path.addQuadCurve(to: p(20, 52), control: p(11, 12))
    path.addQuadCurve(to: p(34, 116), control: p(7, 102))
    path.addQuadCurve(to: p(86, 116), control: p(60, 129))
    path.addQuadCurve(to: p(100, 52), control: p(113, 102))
    path.addQuadCurve(to: p(60, 8), control: p(109, 12))
    path.closeSubpath()
    return path
}

private func drawSittingCat(_ context: GraphicsContext, palette: PetPalette) {
    // Tail curl, tucked behind the body so it reads as attached.
    var tail = Path()
    tail.move(to: p(95, 111))
    tail.addQuadCurve(to: p(114, 66), control: p(123, 101))
    tail.addQuadCurve(to: p(101, 62), control: p(108, 57))
    tail.addQuadCurve(to: p(84, 108), control: p(106, 96))
    tail.closeSubpath()
    shape(context, tail, palette.fur)

    // Ears behind the body outline.
    let earL = triangle(p(33, 0), p(20, 26), p(47, 24))
    let earR = triangle(p(87, 0), p(73, 24), p(100, 26))
    shape(context, earL, palette.patch)
    shape(context, earR, palette.fur)

    // Body.
    let body = sittingCatSilhouette()
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        layer.fill(oval(4, -4, 40, 40), with: .color(palette.patch))
        layer.fill(oval(76, 58, 40, 42), with: .color(palette.secondaryPatch))
        layer.fill(oval(4, 84, 30, 34), with: .color(palette.patch))
    }
    context.stroke(body, with: .color(PetPalette.ink), style: outlineStyle)

    // Inner ears near the tips.
    context.fill(triangle(p(33, 7), p(25, 23), p(42, 22)), with: .color(PetPalette.earPink))
    context.fill(triangle(p(87, 7), p(78, 22), p(95, 23)), with: .color(PetPalette.earPink))

    // Front paws.
    shape(context, oval(38, 104, 20, 15), palette.fur)
    shape(context, oval(62, 104, 20, 15), palette.fur)

    // Minimal face.
    dotEyes(context, leftX: 43, rightX: 77, y: 45)
    nose(context, 60, 53)
    line(context, tinyMouth(60, 56), PetPalette.ink, lineWidth: 1.6)
    softBlush(context, leftX: 32, rightX: 88, y: 52)
}

private func drawLoafCat(_ context: GraphicsContext, palette: PetPalette) {
    // Tail curled along the front.
    let tail = rotate(roundedRect(84, 96, 36, 15, 7.5), -0.12, around: p(104, 103))
    shape(context, tail, palette.fur)

    // A loaf is one long rounded blob.
    let body = roundedRect(10, 50, 100, 62, 31)
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        for index in 0..<4 {
            let stripeX = 56 + CGFloat(index) * 11
            layer.fill(roundedRect(stripeX, 52, 5, 22, 2.5), with: .color(palette.patch.opacity(0.6)))
        }
    }
    context.stroke(body, with: .color(PetPalette.ink), style: outlineStyle)

    // Small ears on the top curve.
    shape(context, triangle(p(40, 30), p(30, 54), p(52, 52)), palette.fur)
    shape(context, triangle(p(66, 30), p(54, 52), p(76, 54)), palette.fur)
    context.fill(triangle(p(41, 37), p(35, 50), p(48, 49)), with: .color(PetPalette.earPink))
    context.fill(triangle(p(65, 37), p(58, 49), p(71, 50)), with: .color(PetPalette.earPink))

    // Sleepy face.
    line(context, downCurve(45, 74, 11, 4.5), PetPalette.ink, lineWidth: 2)
    line(context, downCurve(67, 74, 11, 4.5), PetPalette.ink, lineWidth: 2)
    nose(context, 56, 80, width: 4.5)
    softBlush(context, leftX: 34, rightX: 78, y: 79)

    // Paws tucked under the loaf.
    line(context, downCurve(46, 111, 12, 3.5), PetPalette.ink.opacity(0.55), lineWidth: 1.8)
    line(context, downCurve(66, 111, 12, 3.5), PetPalette.ink.opacity(0.55), lineWidth: 1.8)
}

private func drawPeekingCat(_ context: GraphicsContext, palette: PetPalette, wave: CGFloat) {
    let ledgeY: CGFloat = 96

    // Small, soft ears (drawn first so the head covers their base).
    shape(context, triangle(p(41, 12), p(32, 31), p(52, 29)), palette.fur)
    shape(context, triangle(p(75, 12), p(64, 29), p(84, 31)), palette.fur)

    // Centred head peeking over the ledge.
    let head = oval(24, 26, 64, 66)
    context.fill(head, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: head)
        layer.fill(roundedRect(48, 30, 4, 13, 2), with: .color(palette.patch.opacity(0.5)))
        layer.fill(roundedRect(56, 29, 4, 14, 2), with: .color(palette.patch.opacity(0.5)))
    }
    context.stroke(head, with: .color(PetPalette.ink), style: outlineStyle)
    context.fill(triangle(p(41, 17), p(35, 30), p(48, 28)), with: .color(PetPalette.earPink))
    context.fill(triangle(p(75, 17), p(68, 28), p(81, 30)), with: .color(PetPalette.earPink))

    // The ledge the cat peeks over.
    line(context, segment(p(2, ledgeY), p(118, ledgeY)), PetPalette.ink, lineWidth: 2.4)

    // Resting paw on the ledge.
    shape(context, oval(28, ledgeY - 12, 21, 15), palette.fur)
    line(context, segment(p(35, ledgeY - 9), p(35, ledgeY - 1)), PetPalette.ink, lineWidth: 1.3)
    line(context, segment(p(41, ledgeY - 9), p(41, ledgeY - 1)), PetPalette.ink, lineWidth: 1.3)

    // Raised, waving paw held clear to the side, entirely above the ledge.
    let shoulder = p(91, ledgeY)
    let arm = rotate(roundedRect(87, 56, 9, 42, 4.5), wave, around: shoulder)
    let paw = rotate(oval(83, 44, 17, 16), wave, around: shoulder)
    shape(context, arm, palette.fur)
    shape(context, paw, palette.fur)
    context.drawLayer { layer in
        layer.clip(to: paw)
        layer.stroke(rotate(segment(p(90, 45), p(90, 59)), wave, around: shoulder), with: .color(PetPalette.ink), lineWidth: 1.3)
        layer.stroke(rotate(segment(p(95, 45), p(95, 59)), wave, around: shoulder), with: .color(PetPalette.ink), lineWidth: 1.3)
    }

    // Face: one open eye, one wink, tiny nose and mouth.
    context.fill(oval(44, 55, 6.5, 7.5), with: .color(PetPalette.ink))
    line(context, chevron(66, 59, 10, 6), PetPalette.ink, lineWidth: 2)
    nose(context, 56, 64, width: 4.5)
    line(context, tinyMouth(56, 67), PetPalette.ink, lineWidth: 1.6)
    softBlush(context, leftX: 38, rightX: 74, y: 64, width: 12)

    // A few soft whiskers on the open side.
    line(context, segment(p(14, 60), p(36, 62)), PetPalette.ink.opacity(0.4), lineWidth: 1.2)
    line(context, segment(p(14, 68), p(36, 68)), PetPalette.ink.opacity(0.4), lineWidth: 1.2)
}

private func drawHamster(_ context: GraphicsContext, palette: PetPalette) {
    // Little feet peeking out at the base.
    shape(context, oval(36, 112, 15, 10), palette.fur)
    shape(context, oval(69, 112, 15, 10), palette.fur)

    // Barely-there ears.
    shape(context, oval(34, 20, 18, 18), palette.fur)
    shape(context, oval(68, 20, 18, 18), palette.fur)
    context.fill(oval(39, 25, 8, 8), with: .color(PetPalette.earPink))
    context.fill(oval(73, 25, 8, 8), with: .color(PetPalette.earPink))

    // Soft potato body.
    let body = oval(13, 22, 94, 98)
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        layer.fill(oval(32, 54, 56, 62), with: .color(palette.belly))
    }
    context.stroke(body, with: .color(PetPalette.ink), style: outlineStyle)

    // Tiny hands held together.
    shape(context, oval(45, 88, 14, 13), palette.fur)
    shape(context, oval(61, 88, 14, 13), palette.fur)

    // Minimal face.
    dotEyes(context, leftX: 48, rightX: 72, y: 58, size: 6)
    nose(context, 60, 68, width: 4.5)
    line(context, tinyMouth(60, 71), PetPalette.ink, lineWidth: 1.5)
    softBlush(context, leftX: 36, rightX: 84, y: 66, width: 13)

    // One faint whisker each side.
    line(context, segment(p(20, 64), p(40, 65)), PetPalette.ink.opacity(0.35), lineWidth: 1.1)
    line(context, segment(p(100, 64), p(80, 65)), PetPalette.ink.opacity(0.35), lineWidth: 1.1)
}

#Preview {
    HStack(spacing: 18) {
        ForEach(PetKind.allCases, id: \.self) { kind in
            VStack(spacing: 12) {
                PetIllustration(kind: kind)
                PetIllustration(kind: kind, isCallingAttention: true)
            }
        }
    }
    .padding(28)
    .background(Color(white: 0.96))
}
