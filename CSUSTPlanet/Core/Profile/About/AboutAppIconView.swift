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
private typealias AboutAppIconPlatformImage = NSImage
#else
import UIKit
private typealias AboutAppIconPlatformImage = UIImage
#endif

struct AboutAppIconView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let images = AboutAppIconImages.load()

    var body: some View {
        if let hdrVideoURL = images.hdrVideoURL,
            let sdrImage = images.sdrImage,
            let sdrAlphaMask = images.sdrAlphaMask
        {
            AboutAppIconVideoView(
                videoURL: hdrVideoURL,
                sdrImage: sdrImage,
                alphaMask: sdrAlphaMask,
                showsSweep: !accessibilityReduceMotion
            )
        } else if let hdrImage = images.hdrImage,
            let sdrImage = images.sdrImage
        {
            if accessibilityReduceMotion {
                AboutAppIconStaticView(image: hdrImage, dynamicRange: .high)
            } else {
                AboutAppIconSweepView(hdrImage: hdrImage, sdrImage: sdrImage)
            }
        } else if let sdrImage = images.sdrImage {
            AboutAppIconStaticView(image: sdrImage, dynamicRange: .standard)
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
private struct AboutAppIconStaticView: NSViewRepresentable {
    let image: NSImage
    let dynamicRange: NSImage.DynamicRange

    func makeNSView(context: Context) -> AboutAppIconStaticNSView {
        AboutAppIconStaticNSView(image: image, dynamicRange: dynamicRange)
    }

    func updateNSView(_ nsView: AboutAppIconStaticNSView, context: Context) {
        nsView.updateImage(image, dynamicRange: dynamicRange)
    }
}

private final class AboutAppIconStaticNSView: NSView {
    private let imageView = NSImageView()

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    init(image: NSImage, dynamicRange: NSImage.DynamicRange) {
        super.init(frame: .zero)

        configureImageView(imageView, image: image, dynamicRange: dynamicRange)
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
    }

    func updateImage(_ image: NSImage, dynamicRange: NSImage.DynamicRange) {
        configureImageView(imageView, image: image, dynamicRange: dynamicRange)
    }
}

private struct AboutAppIconSweepView: NSViewRepresentable {
    let hdrImage: NSImage
    let sdrImage: NSImage

    func makeNSView(context: Context) -> AboutAppIconSweepNSView {
        AboutAppIconSweepNSView(hdrImage: hdrImage, sdrImage: sdrImage)
    }

    func updateNSView(_ nsView: AboutAppIconSweepNSView, context: Context) {
        nsView.updateImages(hdrImage: hdrImage, sdrImage: sdrImage)
    }
}

private func configureImageView(
    _ imageView: NSImageView,
    image: NSImage,
    dynamicRange: NSImage.DynamicRange
) {
    imageView.image = image
    imageView.imageAlignment = .alignCenter
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.preferredImageDynamicRange = dynamicRange
}

private final class AboutAppIconSweepNSView: NSView {
    private let sdrImageView = NSImageView()
    private let hdrImageView = NSImageView()
    private let sweepMask = CAGradientLayer()
    private var animatedSize: CGSize = .zero

    init(hdrImage: NSImage, sdrImage: NSImage) {
        super.init(frame: .zero)

        wantsLayer = true
        layer?.masksToBounds = true
        configure(sdrImageView, image: sdrImage, dynamicRange: .standard)
        configure(hdrImageView, image: hdrImage, dynamicRange: .high)

        addSubview(sdrImageView)
        addSubview(hdrImageView)

        AboutAppIconSweepAnimation.configure(sweepMask)
        hdrImageView.wantsLayer = true
        hdrImageView.layer?.mask = sweepMask
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        sdrImageView.frame = bounds
        hdrImageView.frame = bounds

        guard bounds.width > 0,
            bounds.height > 0,
            animatedSize != bounds.size
        else {
            return
        }

        animatedSize = bounds.size
        AboutAppIconSweepAnimation.restart(sweepMask, in: bounds)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil, bounds.width > 0, bounds.height > 0 {
            AboutAppIconSweepAnimation.restart(sweepMask, in: bounds)
        }
    }

    func updateImages(hdrImage: NSImage, sdrImage: NSImage) {
        hdrImageView.image = hdrImage
        sdrImageView.image = sdrImage
    }

    private func configure(
        _ imageView: NSImageView,
        image: NSImage,
        dynamicRange: NSImage.DynamicRange
    ) {
        configureImageView(imageView, image: image, dynamicRange: dynamicRange)
    }
}

private struct AboutAppIconVideoView: NSViewRepresentable {
    let videoURL: URL
    let sdrImage: NSImage
    let alphaMask: CGImage
    let showsSweep: Bool

    func makeNSView(context: Context) -> AboutAppIconVideoNSView {
        AboutAppIconVideoNSView(
            videoURL: videoURL,
            sdrImage: sdrImage,
            alphaMask: alphaMask,
            showsSweep: showsSweep
        )
    }

    func updateNSView(_ nsView: AboutAppIconVideoNSView, context: Context) {
        nsView.update(sdrImage: sdrImage, showsSweep: showsSweep)
    }
}

private final class AboutAppIconVideoNSView: NSView {
    private let sdrImageView = NSImageView()
    private let videoOverlayView = NSView()
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    private let alphaMaskLayer = CALayer()
    private let sweepMask = CAGradientLayer()
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var animatedSize: CGSize = .zero
    private var hasRequestedStillFrame = false
    private var showsSweep: Bool

    init(
        videoURL: URL,
        sdrImage: NSImage,
        alphaMask: CGImage,
        showsSweep: Bool
    ) {
        let player = AVPlayer(url: videoURL)
        self.player = player
        playerLayer = AVPlayerLayer(player: player)
        self.showsSweep = showsSweep
        super.init(frame: .zero)

        wantsLayer = true
        layer?.masksToBounds = true
        configureImageView(sdrImageView, image: sdrImage, dynamicRange: .standard)

        videoOverlayView.wantsLayer = true
        videoOverlayView.layer?.masksToBounds = true
        videoOverlayView.layer?.wantsExtendedDynamicRangeContent = true
        playerLayer.wantsExtendedDynamicRangeContent = true
        playerLayer.videoGravity = .resizeAspect

        alphaMaskLayer.contents = alphaMask
        alphaMaskLayer.contentsGravity = .resize
        playerLayer.mask = alphaMaskLayer
        videoOverlayView.layer?.addSublayer(playerLayer)

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

    deinit {
        player.pause()
        playerItemStatusObservation?.invalidate()
    }

    override func layout() {
        super.layout()

        sdrImageView.frame = bounds
        videoOverlayView.frame = bounds
        playerLayer.frame = videoOverlayView.bounds
        alphaMaskLayer.frame = playerLayer.bounds

        restartSweepIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            restartSweepIfNeeded(force: true)
        }
    }

    func update(sdrImage: NSImage, showsSweep: Bool) {
        sdrImageView.image = sdrImage

        guard self.showsSweep != showsSweep else {
            return
        }

        self.showsSweep = showsSweep
        animatedSize = .zero
        updateSweepMask()
        restartSweepIfNeeded(force: true)
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
        guard let overlayLayer = videoOverlayView.layer else {
            return
        }

        if showsSweep {
            overlayLayer.mask = sweepMask
        } else {
            overlayLayer.mask = nil
            sweepMask.removeAnimation(forKey: AboutAppIconSweepAnimation.animationKey)
        }
    }

    private func restartSweepIfNeeded(force: Bool = false) {
        guard showsSweep,
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
#else
private struct AboutAppIconStaticView: UIViewRepresentable {
    let image: UIImage
    let dynamicRange: UIImage.DynamicRange

    func makeUIView(context: Context) -> UIImageView {
        makeImageView(image: image, dynamicRange: dynamicRange)
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        uiView.preferredImageDynamicRange = dynamicRange
    }
}

private func makeImageView(
    image: UIImage,
    dynamicRange: UIImage.DynamicRange
) -> UIImageView {
    let imageView = UIImageView()
    imageView.image = image
    imageView.contentMode = .scaleAspectFit
    imageView.preferredImageDynamicRange = dynamicRange
    return imageView
}

private struct AboutAppIconSweepView: UIViewRepresentable {
    let hdrImage: UIImage
    let sdrImage: UIImage

    func makeUIView(context: Context) -> AboutAppIconSweepUIView {
        AboutAppIconSweepUIView(hdrImage: hdrImage, sdrImage: sdrImage)
    }

    func updateUIView(_ uiView: AboutAppIconSweepUIView, context: Context) {
        uiView.updateImages(hdrImage: hdrImage, sdrImage: sdrImage)
    }
}

private final class AboutAppIconSweepUIView: UIView {
    private let sdrImageView = UIImageView()
    private let hdrImageView = UIImageView()
    private let sweepMask = CAGradientLayer()
    private var animatedSize: CGSize = .zero

    init(hdrImage: UIImage, sdrImage: UIImage) {
        super.init(frame: .zero)

        clipsToBounds = true
        sdrImageView.image = sdrImage
        sdrImageView.contentMode = .scaleAspectFit
        sdrImageView.preferredImageDynamicRange = .standard
        configure(hdrImageView, image: hdrImage, dynamicRange: .high)

        addSubview(sdrImageView)
        addSubview(hdrImageView)

        AboutAppIconSweepAnimation.configure(sweepMask)
        hdrImageView.layer.mask = sweepMask
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sdrImageView.frame = bounds
        hdrImageView.frame = bounds

        guard bounds.width > 0,
            bounds.height > 0,
            animatedSize != bounds.size
        else {
            return
        }

        animatedSize = bounds.size
        AboutAppIconSweepAnimation.restart(sweepMask, in: bounds)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil, bounds.width > 0, bounds.height > 0 {
            AboutAppIconSweepAnimation.restart(sweepMask, in: bounds)
        }
    }

    func updateImages(hdrImage: UIImage, sdrImage: UIImage) {
        hdrImageView.image = hdrImage
        sdrImageView.image = sdrImage
    }

    private func configure(
        _ imageView: UIImageView,
        image: UIImage,
        dynamicRange: UIImage.DynamicRange
    ) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.preferredImageDynamicRange = dynamicRange
    }
}

private struct AboutAppIconVideoView: UIViewRepresentable {
    let videoURL: URL
    let sdrImage: UIImage
    let alphaMask: CGImage
    let showsSweep: Bool

    func makeUIView(context: Context) -> AboutAppIconVideoUIView {
        AboutAppIconVideoUIView(
            videoURL: videoURL,
            sdrImage: sdrImage,
            alphaMask: alphaMask,
            showsSweep: showsSweep
        )
    }

    func updateUIView(_ uiView: AboutAppIconVideoUIView, context: Context) {
        uiView.update(sdrImage: sdrImage, showsSweep: showsSweep)
    }
}

private final class AboutAppIconVideoUIView: UIView {
    private let sdrImageView = UIImageView()
    private let videoOverlayView = UIView()
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    private let alphaMaskLayer = CALayer()
    private let sweepMask = CAGradientLayer()
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var animatedSize: CGSize = .zero
    private var hasRequestedStillFrame = false
    private var showsSweep: Bool

    init(
        videoURL: URL,
        sdrImage: UIImage,
        alphaMask: CGImage,
        showsSweep: Bool
    ) {
        let player = AVPlayer(url: videoURL)
        self.player = player
        playerLayer = AVPlayerLayer(player: player)
        self.showsSweep = showsSweep
        super.init(frame: .zero)

        clipsToBounds = true
        sdrImageView.image = sdrImage
        sdrImageView.contentMode = .scaleAspectFit
        sdrImageView.preferredImageDynamicRange = .standard

        videoOverlayView.layer.masksToBounds = true
        videoOverlayView.layer.wantsExtendedDynamicRangeContent = true
        playerLayer.wantsExtendedDynamicRangeContent = true
        playerLayer.videoGravity = .resizeAspect

        alphaMaskLayer.contents = alphaMask
        alphaMaskLayer.contentsGravity = .resize
        playerLayer.mask = alphaMaskLayer
        videoOverlayView.layer.addSublayer(playerLayer)

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

    deinit {
        player.pause()
        playerItemStatusObservation?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sdrImageView.frame = bounds
        videoOverlayView.frame = bounds
        playerLayer.frame = videoOverlayView.bounds
        alphaMaskLayer.frame = playerLayer.bounds

        restartSweepIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            restartSweepIfNeeded(force: true)
        }
    }

    func update(sdrImage: UIImage, showsSweep: Bool) {
        sdrImageView.image = sdrImage

        guard self.showsSweep != showsSweep else {
            return
        }

        self.showsSweep = showsSweep
        animatedSize = .zero
        updateSweepMask()
        restartSweepIfNeeded(force: true)
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
            videoOverlayView.layer.mask = sweepMask
        } else {
            videoOverlayView.layer.mask = nil
            sweepMask.removeAnimation(forKey: AboutAppIconSweepAnimation.animationKey)
        }
    }

    private func restartSweepIfNeeded(force: Bool = false) {
        guard showsSweep,
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
#endif

private enum AboutAppIconSweepAnimation {
    static let stripWidthRatio: CGFloat = 0.6
    #if os(macOS)
    static let stripAngle: CGFloat = 32 * .pi / 180
    #else
    static let stripAngle: CGFloat = -32 * .pi / 180
    #endif
    static let sweepDuration: CFTimeInterval = 3.8
    static let pauseDuration: CFTimeInterval = 1.2
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

private struct AboutAppIconImages {
    let hdrImage: AboutAppIconPlatformImage?
    let hdrVideoURL: URL?
    let sdrImage: AboutAppIconPlatformImage?
    let sdrAlphaMask: CGImage?

    static func load() -> AboutAppIconImages {
        let hdrImage = loadBundleCGImage(
            resource: "AboutAppIcon-HDR",
            extension: "heic",
            decodeRequest: kCGImageSourceDecodeToHDR
        )
        let sdrImage = loadBundleCGImage(
            resource: "AboutAppIcon-SDR",
            extension: "png",
            decodeRequest: kCGImageSourceDecodeToSDR
        )

        return AboutAppIconImages(
            hdrImage: hdrImage.map(platformImage),
            hdrVideoURL: Bundle.main.url(
                forResource: "AboutAppIcon-HDR",
                withExtension: "mov"
            ),
            sdrImage: sdrImage.map(platformImage),
            sdrAlphaMask: sdrImage
        )
    }

    private static func loadBundleCGImage(
        resource: String,
        extension fileExtension: String,
        decodeRequest: CFString
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

        let options = [kCGImageSourceDecodeRequest: decodeRequest] as CFDictionary

        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            return nil
        }

        return image
    }

    private static func platformImage(_ image: CGImage) -> AboutAppIconPlatformImage {
        #if os(macOS)
        return NSImage(
            cgImage: image,
            size: NSSize(width: image.width, height: image.height)
        )
        #else
        return UIImage(cgImage: image)
        #endif
    }
}
