import AVFoundation
import Foundation
import UIKit

final class BackgroundAudioKeepAlive {
    private var player: AVAudioPlayer?
    private var observers: [NSObjectProtocol] = []

    var isRunning: Bool {
        player?.isPlaying ?? false
    }

    func start() throws {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let player = try AVAudioPlayer(data: Self.makeKeepAliveWAV())
        player.numberOfLoops = -1
        player.volume = 1
        player.prepareToPlay()
        player.play()

        self.player = player
        installObservers()
    }

    func stop() {
        removeObservers()
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func resumePlayback() {
        guard let player else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        if !player.isPlaying {
            player.play()
        }
    }

    private func installObservers() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumePlayback()
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard
                let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                AVAudioSession.InterruptionType(rawValue: rawType) == .ended
            else { return }
            self?.resumePlayback()
        })
    }

    private func removeObservers() {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
    }

    private static func makeKeepAliveWAV(sampleRate: UInt32 = 8_000, seconds: UInt32 = 1) -> Data {
        let channelCount: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * (bitsPerSample / 8)
        let frameCount = sampleRate * seconds
        let dataSize = frameCount * UInt32(blockAlign)

        var data = Data()
        data.appendASCII("RIFF")
        data.appendLittleEndian(36 + dataSize)
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(channelCount)
        data.appendLittleEndian(sampleRate)
        data.appendLittleEndian(byteRate)
        data.appendLittleEndian(blockAlign)
        data.appendLittleEndian(bitsPerSample)
        data.appendASCII("data")
        data.appendLittleEndian(dataSize)

        for frame in 0..<frameCount {
            let sample: Int16 = (frame / 10).isMultiple(of: 2) ? 1 : -1
            data.appendLittleEndian(sample)
        }

        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { buffer in
            append(contentsOf: buffer)
        }
    }
}
