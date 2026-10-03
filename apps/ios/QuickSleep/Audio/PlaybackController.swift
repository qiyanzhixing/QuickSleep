import AVFoundation
import MediaPlayer
import Foundation
import Combine

@MainActor final class PlaybackController: ObservableObject {
    enum Status { case idle, loading, active, preview, complete, error }
    @Published private(set) var status = Status.idle
    @Published private(set) var config: SessionConfig?
    @Published private(set) var elapsed = 0.0
    @Published private(set) var playing = false
    @Published private(set) var previewMode: SoundMode?
    private var player = AVPlayer()
    private var timeObserver: Any?
    private var rateObserver: NSKeyValueObservation?
    private var itemObserver: NSKeyValueObservation?
    private var notifications: [NSObjectProtocol] = []
    private var endObserver: NSObjectProtocol?
    private var file: URL?
    private var token: CancellationToken?
    private var request = UUID()
    private var interrupted = false
    private let worker = DispatchQueue(label: "quicksleep.audio.assembly", qos: .userInitiated)
    private let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    init() {
        let stale = (try? FileManager.default.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil)) ?? []
        for url in stale where url.lastPathComponent.hasPrefix("session-") { try? FileManager.default.removeItem(at: url) }
        observePlayer()
        let center = NotificationCenter.default
        notifications.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue
            Task { @MainActor in
                self?.interrupted = began
                if began { self?.pause() }
                // Interruption end only releases the guard; the user must resume.
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            if (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt) == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in self?.pause() }
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.finish(.error)
                if let observer = self.timeObserver { self.player.removeTimeObserver(observer) }
                self.rateObserver = nil
                self.player = AVPlayer()
                self.observePlayer()
            }
        })
        configureRemoteCommands()
    }

    private func observePlayer() {
        player.actionAtItemEnd = .pause
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 24000), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self, self.status == .active else { return }
                self.elapsed = time.seconds.isFinite ? time.seconds : 0
            }
        }
        rateObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let playing = player.timeControlStatus == .playing
            Task { @MainActor in
                guard let self, self.status == .active || self.status == .preview else { return }
                self.playing = playing
            }
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.play() }; return .success }
        commands.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.pause() }; return .success }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in guard let self else { return }; if self.playing { self.pause() } else { self.play() } }
            return .success
        }
        commands.stopCommand.addTarget { [weak self] _ in Task { @MainActor in self?.stop() }; return .success }
        commands.nextTrackCommand.isEnabled = false; commands.previousTrackCommand.isEnabled = false
        commands.skipForwardCommand.isEnabled = false; commands.skipBackwardCommand.isEnabled = false
        commands.seekForwardCommand.isEnabled = false; commands.seekBackwardCommand.isEnabled = false
        commands.changePlaybackPositionCommand.isEnabled = false
        commands.changePlaybackRateCommand.isEnabled = false
        commands.changeRepeatModeCommand.isEnabled = false; commands.changeShuffleModeCommand.isEnabled = false
        updateRemote()
    }

    private func updateRemote() {
        let enabled = status == .active
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = enabled
        commands.pauseCommand.isEnabled = enabled
        commands.togglePlayPauseCommand.isEnabled = enabled
        commands.stopCommand.isEnabled = enabled
        guard enabled, let config else { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: localized(config.mode.nameKey, language: config.language),
            MPMediaItemPropertyArtist: localized("sessionTitle", language: config.language),
            MPMediaItemPropertyPlaybackDuration: Double(config.minutes * 60),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
    }

    func start(_ value: SessionConfig) {
        guard status != .loading && status != .active else { return }
        do {
            let plan = try SessionPlan(config: value)
            reset()
            interrupted = false // A new explicit user request may recover from an unmatched interruption.
            config = value; status = .loading
            let id = request
            let cancellation = CancellationToken()
            token = cancellation
            let output = cache.appendingPathComponent("session-\(id.uuidString).wav")
            // Resolve paths on the main actor before dispatching independent file work.
            let sources = try Dictionary(uniqueKeysWithValues: Set(plan.segments.map(\.path)).map { path in
                guard let url = Bundle.main.resourceURL?.appendingPathComponent("assets/\(path)"), FileManager.default.fileExists(atPath: url.path) else { throw SessionError.invalidAudio }
                return (path, url)
            })
            worker.async { [weak self] in
                do {
                    try WaveAssembler.write(plan: plan, output: output, source: { path in
                        guard let url = sources[path] else { throw SessionError.invalidAudio }; return url
                    }, cancelled: { cancellation.isCancelled })
                    Task { @MainActor in
                        guard let self, self.request == id, !cancellation.isCancelled else { try? FileManager.default.removeItem(at: output); return }
                        self.file = output
                        self.status = .active
                        self.load(output)
                        self.play(userInitiated: false)
                    }
                } catch {
                    Task { @MainActor in if let self, self.request == id, !cancellation.isCancelled { self.finish(.error) } }
                }
            }
        } catch { finish(.error) }
    }

    func preview(_ mode: SoundMode, language: AppLanguage) {
        guard status != .loading && status != .active else { return }
        reset(); config = nil
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("assets/audio/\(language.rawValue)/\(mode.rawValue)_preview.wav"), FileManager.default.fileExists(atPath: url.path) else { finish(.error); return }
        previewMode = mode; status = .preview
        load(url); play()
    }
    func closePreview() { if status == .preview { stop() } }

    private func load(_ url: URL) {
        let item = AVPlayerItem(url: url)
        let id = request
        itemObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed { Task { @MainActor in if self?.request == id { self?.finish(.error) } } }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in guard let self, self.request == id else { return }; self.finish(self.status == .preview ? .idle : .complete) }
        }
        player.replaceCurrentItem(with: item)
    }

    func play(userInitiated: Bool = true) {
        guard (userInitiated || !interrupted), status == .active || status == .preview else { return }
        do { try configureSession(); interrupted = false; player.play(); playing = true; updateRemote() }
        catch { finish(.error) }
    }
    func pause() { player.pause(); playing = false; updateRemote() }
    func stop() { finish(.idle) }

    private func reset() {
        request = UUID(); token?.cancel(); token = nil
        player.pause(); player.replaceCurrentItem(with: nil)
        itemObserver = nil
        if let observer = endObserver { NotificationCenter.default.removeObserver(observer); endObserver = nil }
        if let file { try? FileManager.default.removeItem(at: file) }; file = nil
        previewMode = nil; elapsed = 0; playing = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func finish(_ value: Status) {
        reset()
        status = value
        if value == .idle { config = nil }
        if value == .complete { elapsed = Double((config?.minutes ?? 0) * 60) }
        updateRemote()
    }
}
