import AVFoundation
import Foundation

final class BackgroundAudioKeepAlive {
    private var player: AVAudioPlayer?

    var isRunning: Bool {
        player?.isPlaying ?? false
    }

    func start() throws {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)

        let player = try AVAudioPlayer(data: Self.makeSilentWAV())
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        player.play()

        self.player = player
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private static func makeSilentWAV(sampleRate: UInt32 = 8_000, seconds: UInt32 = 1) -> Data {
        let channelCount: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * (bitsPerSample / 8)
        let dataSize = sampleRate * seconds * UInt32(blockAlign)

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
        data.append(Data(repeating: 0, count: Int(dataSize)))
        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { buffer in
            append(contentsOf: buffer)
        }
    }
}
