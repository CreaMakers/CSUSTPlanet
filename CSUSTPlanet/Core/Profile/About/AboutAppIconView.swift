//
//  AboutAppIconView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/7/18.
//

import AVFoundation
import ImageIO
import QuartzCore
import SwiftUI

#if os(macOS)
import AppKit
private typealias AboutAppIconPlatformView = NSView
private typealias AboutAppIconPlatformImageView = NSImageView
#else
import UIKit
private typealias AboutAppIconPlatformView = UIView
private typealias AboutAppIconPlatformImageView = UIImageView
#endif

struct AboutAppIconView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private static let resources = AboutAppIconResources.load()

    var body: some View {
        if let videoURL = Self.resources.videoURL,
            let sdrImage = Self.resources.sdrImage
        {
            AboutAppIconVideoView(
                videoURL: videoURL,
                sdrImage: sdrImage,
                showsSweep: !accessibilityReduceMotion
            )
        } else if let sdrImage = Self.resources.sdrImage {
            Image(decorative: sdrImage, scale: 1)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(12)
        }
    }
}

#if os(macOS)
private struct AboutAppIconVideoView: NSViewRepresentable {
    let videoURL: URL
    let sdrImage: CGImage
    let showsSweep: Bool

    func makeNSView(context: Context) -> AboutAppIconVideoPlatformView {
        AboutAppIconVideoPlatformView(
            videoURL: videoURL,
            sdrImage: sdrImage,
            showsSweep: showsSweep
        )
    }

    func updateNSView(_ nsView: AboutAppIconVideoPlatformView, context: Context) {
        nsView.update(showsSweep: showsSweep)
    }
}
#else
private struct AboutAppIconVideoView: UIViewRepresentable {
    let videoURL: URL
    let sdrImage: CGImage
    let showsSweep: Bool

    func makeUIView(context: Context) -> AboutAppIconVideoPlatformView {
        AboutAppIconVideoPlatformView(
            videoURL: videoURL,
            sdrImage: sdrImage,
            showsSweep: showsSweep
        )
    }

    func updateUIView(_ uiView: AboutAppIconVideoPlatformView, context: Context) {
        uiView.update(showsSweep: showsSweep)
    }
}
#endif

private final class AboutAppIconVideoPlatformView: AboutAppIconPlatformView {
    private let sdrImageView = AboutAppIconPlatformImageView()
    private let videoOverlayView = AboutAppIconPlatformView()
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    private let alphaMaskLayer = CALayer()
    private let sweepMask = CAGradientLayer()
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var animatedSize: CGSize = .zero
    private var hasRequestedStillFrame = false
    private var showsSweep: Bool

    init(videoURL: URL, sdrImage: CGImage, showsSweep: Bool) {
        let player = AVPlayer(url: videoURL)
        self.player = player
        playerLayer = AVPlayerLayer(player: player)
        self.showsSweep = showsSweep
        super.init(frame: .zero)

        configureViews(sdrImage: sdrImage)
        configureVideoLayer(alphaMask: sdrImage)
        AboutAppIconSweepAnimation.configure(sweepMask)
        updateSweepMask()

        addSubview(sdrImageView)
        addSubview(videoOverlayView)

        player.isMuted = true
        observePlaybackReadiness()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(macOS)
    override func layout() {
        super.layout()
        layoutContent()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        restartSweepIfNeeded(force: true)
    }
    #else
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContent()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartSweepIfNeeded(force: true)
    }
    #endif

    func update(showsSweep: Bool) {
        guard self.showsSweep != showsSweep else {
            return
        }

        self.showsSweep = showsSweep
        animatedSize = .zero
        updateSweepMask()
        restartSweepIfNeeded(force: true)
    }

    private var videoOverlayLayer: CALayer {
        #if os(macOS)
        videoOverlayView.layer!
        #else
        videoOverlayView.layer
        #endif
    }

    private func configureViews(sdrImage: CGImage) {
        #if os(macOS)
        wantsLayer = true
        layer?.masksToBounds = true
        sdrImageView.imageAlignment = .alignCenter
        sdrImageView.imageScaling = .scaleProportionallyUpOrDown
        sdrImageView.image = NSImage(
            cgImage: sdrImage,
            size: NSSize(width: sdrImage.width, height: sdrImage.height)
        )
        videoOverlayView.wantsLayer = true
        #else
        clipsToBounds = true
        sdrImageView.contentMode = .scaleAspectFit
        sdrImageView.preferredImageDynamicRange = .standard
        sdrImageView.image = UIImage(cgImage: sdrImage)
        #endif
    }

    private func configureVideoLayer(alphaMask: CGImage) {
        videoOverlayLayer.masksToBounds = true
        videoOverlayLayer.wantsExtendedDynamicRangeContent = true
        playerLayer.wantsExtendedDynamicRangeContent = true
        playerLayer.videoGravity = .resizeAspect

        alphaMaskLayer.contents = alphaMask
        alphaMaskLayer.contentsGravity = .resize
        playerLayer.mask = alphaMaskLayer
        videoOverlayLayer.addSublayer(playerLayer)
    }

    private func layoutContent() {
        sdrImageView.frame = bounds
        videoOverlayView.frame = bounds
        playerLayer.frame = videoOverlayView.bounds
        alphaMaskLayer.frame = playerLayer.bounds
        restartSweepIfNeeded()
    }

    private func observePlaybackReadiness() {
        playerItemStatusObservation = player.currentItem?.observe(
            \.status,
            options: [.initial, .new]
        ) { [weak self] item, _ in
            guard item.status == .readyToPlay else {
                return
            }

            DispatchQueue.main.async {
                self?.displayStillFrame()
            }
        }
    }

    private func displayStillFrame() {
        guard !hasRequestedStillFrame else {
            return
        }

        hasRequestedStillFrame = true
        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak player] _ in
            player?.pause()
        }
    }

    private func updateSweepMask() {
        if showsSweep {
            videoOverlayLayer.mask = sweepMask
        } else {
            videoOverlayLayer.mask = nil
            sweepMask.removeAnimation(forKey: AboutAppIconSweepAnimation.animationKey)
        }
    }

    private func restartSweepIfNeeded(force: Bool = false) {
        guard showsSweep,
            window != nil,
            bounds.width > 0,
            bounds.height > 0,
            force || animatedSize != bounds.size
        else {
            return
        }

        animatedSize = bounds.size
        AboutAppIconSweepAnimation.restart(sweepMask, in: bounds)
    }
}

private enum AboutAppIconSweepAnimation {
    static let stripWidthRatio: CGFloat = 0.6
    #if os(macOS)
    static let stripAngle: CGFloat = 32 * .pi / 180
    #else
    static let stripAngle: CGFloat = -32 * .pi / 180
    #endif
    static let sweepDuration: CFTimeInterval = 3.8
    static let pauseDuration: CFTimeInterval = 0.4
    static let loopDuration = sweepDuration + pauseDuration
    static let animationKey = "aboutAppIconSweep"

    static func configure(_ mask: CAGradientLayer) {
        mask.colors = [
            CGColor(gray: 0, alpha: 0),
            CGColor(gray: 0, alpha: 1),
            CGColor(gray: 0, alpha: 1),
            CGColor(gray: 0, alpha: 0),
        ]
        mask.startPoint = CGPoint(x: 0, y: 0.5)
        mask.endPoint = CGPoint(x: 1, y: 0.5)
    }

    static func restart(_ mask: CAGradientLayer, in bounds: CGRect) {
        mask.removeAnimation(forKey: animationKey)

        let stripWidth = bounds.width * stripWidthRatio
        let stripHeight = hypot(bounds.width, bounds.height) * 1.35
        let horizontalOverhang = (abs(sin(stripAngle)) * stripHeight + stripWidth) / 2
        let startX = -horizontalOverhang
        let endX = bounds.width + horizontalOverhang

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.bounds = CGRect(x: 0, y: 0, width: stripWidth, height: stripHeight)
        mask.position = CGPoint(x: startX, y: bounds.midY)
        mask.transform = CATransform3DMakeRotation(stripAngle, 0, 0, 1)
        CATransaction.commit()

        let travel = CABasicAnimation(keyPath: "position.x")
        travel.fromValue = startX
        travel.toValue = endX
        travel.beginTime = 0
        travel.duration = sweepDuration
        travel.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        travel.fillMode = .forwards
        travel.isRemovedOnCompletion = false

        let loop = CAAnimationGroup()
        loop.animations = [travel]
        loop.duration = loopDuration
        loop.repeatCount = .infinity
        loop.isRemovedOnCompletion = false

        mask.add(loop, forKey: animationKey)
    }
}

private struct AboutAppIconResources {
    let videoURL: URL?
    let sdrImage: CGImage?

    static func load() -> AboutAppIconResources {
        let sdrImage = loadBundleCGImage(
            resource: "AboutAppIcon-SDR",
            extension: "png"
        )

        return AboutAppIconResources(
            videoURL: Bundle.main.url(
                forResource: "AboutAppIcon-HDR",
                withExtension: "mov"
            ),
            sdrImage: sdrImage
        )
    }

    private static func loadBundleCGImage(
        resource: String,
        extension fileExtension: String
    ) -> CGImage? {
        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: fileExtension
            ),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
