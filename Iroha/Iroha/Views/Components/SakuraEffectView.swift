//
//  SakuraEffectView.swift
//  Iroha
//

import SwiftUI

struct SakuraEffectView: UIViewRepresentable {
    enum Intensity {
        case light, medium, grand

        var emitDuration: TimeInterval {
            switch self {
            case .light: 2
            case .medium: 2.5
            case .grand: 4
            }
        }

        var totalDuration: TimeInterval {
            emitDuration + 5
        }

        fileprivate var birthRate: Float {
            switch self {
            case .light: 4
            case .medium: 10
            case .grand: 20
            }
        }
    }

    let intensity: Intensity

    func makeUIView(context: Context) -> SakuraEmitterUIView {
        SakuraEmitterUIView(intensity: intensity)
    }

    func updateUIView(_ uiView: SakuraEmitterUIView, context: Context) {}
}

final class SakuraEmitterUIView: UIView {
    private let emitterLayer = CAEmitterLayer()
    private let intensity: SakuraEffectView.Intensity

    init(intensity: SakuraEffectView.Intensity) {
        self.intensity = intensity
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        setupEmitter()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.5, height: 1)
        emitterLayer.frame = bounds
    }

    private func setupEmitter() {
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .oldestFirst

        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (1.00, 0.82, 0.86),
            (1.00, 0.75, 0.82),
            (1.00, 0.88, 0.91),
            (0.96, 0.78, 0.83),
        ]

        emitterLayer.emitterCells = colors.map { r, g, b in
            let cell = CAEmitterCell()
            cell.birthRate = intensity.birthRate / Float(colors.count)
            cell.lifetime = 5
            cell.lifetimeRange = 1
            cell.velocity = 40
            cell.velocityRange = 20
            cell.emissionLongitude = .pi / 2
            cell.emissionRange = .pi / 6
            cell.xAcceleration = 8
            cell.yAcceleration = 3
            cell.spin = 0.8
            cell.spinRange = 2
            cell.scale = 0.05
            cell.scaleRange = 0.025
            cell.scaleSpeed = -0.003
            cell.alphaSpeed = -0.12
            cell.contents = Self.petalImage(r: r, g: g, b: b).cgImage
            return cell
        }

        layer.addSublayer(emitterLayer)

        DispatchQueue.main.asyncAfter(deadline: .now() + intensity.emitDuration) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
    }

    private static func petalImage(r: CGFloat, g: CGFloat, b: CGFloat) -> UIImage {
        let size = CGSize(width: 120, height: 80)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 40))
            path.addCurve(to: CGPoint(x: 120, y: 40),
                          controlPoint1: CGPoint(x: 35, y: -10),
                          controlPoint2: CGPoint(x: 85, y: -10))
            path.addCurve(to: CGPoint(x: 0, y: 40),
                          controlPoint1: CGPoint(x: 85, y: 90),
                          controlPoint2: CGPoint(x: 35, y: 90))
            UIColor(red: r, green: g, blue: b, alpha: 0.85).setFill()
            path.fill()
        }
    }
}
