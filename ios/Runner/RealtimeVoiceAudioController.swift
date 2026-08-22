import AVFAudio
import Flutter

/// Native PCM bridge for Gemini Live. The input tap yields mono PCM16 at
/// 16 kHz; the player accepts mono PCM16 at 24 kHz. Buffers remain in memory
/// only and are released with the voice session.
final class RealtimeVoiceAudioController: NSObject, FlutterStreamHandler {
  private static let methodChannelName = "com.nanobioai.app/realtime_voice_audio"
  private static let inputEventChannelName =
    "com.nanobioai.app/realtime_voice_audio/input_pcm"
  private static let inputSampleRate: Double = 16_000
  private static let outputSampleRate: Double = 24_000

  private let audioSession = AVAudioSession.sharedInstance()
  private let audioEngine = AVAudioEngine()
  private let playerNode = AVAudioPlayerNode()
  private let serialQueue = DispatchQueue(label: "com.nanobioai.app.realtimeVoice")
  private var eventSink: FlutterEventSink?
  private var inputConverter: AVAudioConverter?
  private var inputFormat: AVAudioFormat?
  private var captureActive = false
  private var outputMuted = false
  private var playerConnected = false

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    audioEngine.attach(playerNode)
    MethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    EventChannel(
      name: Self.inputEventChannelName,
      binaryMessenger: messenger
    ).setStreamHandler(self)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: audioSession
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    dispose()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func dispose() {
    serialQueue.sync {
      stopCaptureLocked()
      playerNode.stop()
      audioEngine.stop()
      inputConverter = nil
      inputFormat = nil
      outputMuted = false
      try? audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepare":
      ensureRecordPermission { [weak self] granted in
        guard let self else { return }
        guard granted else {
          result(FlutterError(
            code: "permission_denied",
            message: "Microphone permission has not been granted.",
            details: nil
          ))
          return
        }
        do {
          try self.serialQueue.sync { try self.prepareLocked() }
          result(nil)
        } catch {
          result(FlutterError(code: "audio_unavailable", message: error.localizedDescription, details: nil))
        }
      }
    case "startCapture":
      perform(result) { try self.startCaptureLocked() }
    case "pauseCapture":
      perform(result) { self.stopCaptureLocked() }
    case "resumeCapture":
      perform(result) { try self.startCaptureLocked() }
    case "playPcm":
      let values = call.arguments as? [String: Any]
      guard let data = values?["pcm"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "audio_unavailable", message: "Missing PCM output.", details: nil))
        return
      }
      perform(result) { try self.playPcmLocked(data.data) }
    case "stopPlayback":
      perform(result) { self.playerNode.stop() }
    case "setOutputMuted":
      let values = call.arguments as? [String: Any]
      let muted = values?["muted"] as? Bool ?? false
      perform(result) {
        self.outputMuted = muted
        if muted { self.playerNode.stop() }
      }
    case "dispose":
      dispose()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func perform(_ result: @escaping FlutterResult, action: @escaping () throws -> Void) {
    serialQueue.async {
      do {
        try action()
        result(nil)
      } catch {
        result(FlutterError(code: "audio_unavailable", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func ensureRecordPermission(completion: @escaping (Bool) -> Void) {
    switch audioSession.recordPermission {
    case .granted:
      completion(true)
    case .denied:
      completion(false)
    case .undetermined:
      audioSession.requestRecordPermission { granted in
        DispatchQueue.main.async { completion(granted) }
      }
    @unknown default:
      completion(false)
    }
  }

  private func prepareLocked() throws {
    try audioSession.setCategory(
      .playAndRecord,
      mode: .voiceChat,
      options: [.allowBluetooth, .defaultToSpeaker]
    )
    try audioSession.setActive(true)

    let inputNode = audioEngine.inputNode
    if #available(iOS 13.0, *) {
      try? inputNode.setVoiceProcessingEnabled(true)
    }
    if !playerConnected {
      let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: Self.outputSampleRate,
        channels: 1,
        interleaved: true
      )!
      audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)
      playerConnected = true
    }
    if !audioEngine.isRunning {
      audioEngine.prepare()
      try audioEngine.start()
    }
  }

  private func startCaptureLocked() throws {
    try prepareLocked()
    guard !captureActive else { return }
    let inputNode = audioEngine.inputNode
    let sourceFormat = inputNode.outputFormat(forBus: 0)
    guard let targetFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: Self.inputSampleRate,
      channels: 1,
      interleaved: true
    ) else {
      throw VoiceAudioError.unsupportedInputFormat
    }
    guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
      throw VoiceAudioError.unsupportedInputFormat
    }
    inputFormat = targetFormat
    inputConverter = converter
    captureActive = true

    inputNode.installTap(onBus: 0, bufferSize: 1_024, format: nil) { [weak self] buffer, _ in
      self?.emitInput(buffer)
    }
  }

  private func stopCaptureLocked() {
    captureActive = false
    audioEngine.inputNode.removeTap(onBus: 0)
  }

  private func emitInput(_ sourceBuffer: AVAudioPCMBuffer) {
    guard captureActive, let converter = inputConverter, let targetFormat = inputFormat else {
      return
    }
    let estimatedFrameCount = max(
      1,
      Int(Double(sourceBuffer.frameLength) * targetFormat.sampleRate / sourceBuffer.format.sampleRate) + 64
    )
    guard let outputBuffer = AVAudioPCMBuffer(
      pcmFormat: targetFormat,
      frameCapacity: AVAudioFrameCount(estimatedFrameCount)
    ) else {
      return
    }

    var conversionError: NSError?
    var suppliedInput = false
    converter.convert(to: outputBuffer, error: &conversionError) { _, status in
      if suppliedInput {
        status.pointee = .noDataNow
        return nil
      }
      suppliedInput = true
      status.pointee = .haveData
      return sourceBuffer
    }
    guard conversionError == nil, outputBuffer.frameLength > 0 else { return }
    let audioBuffer = outputBuffer.audioBufferList.pointee.mBuffers
    guard let rawData = audioBuffer.mData, audioBuffer.mDataByteSize > 0 else { return }
    let data = Data(bytes: rawData, count: Int(audioBuffer.mDataByteSize))
    eventSink?(FlutterStandardTypedData(bytes: data))
  }

  private func playPcmLocked(_ data: Data) throws {
    guard !data.isEmpty, !outputMuted else { return }
    try prepareLocked()
    guard let format = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: Self.outputSampleRate,
      channels: 1,
      interleaved: true
    ), let buffer = AVAudioPCMBuffer(
      pcmFormat: format,
      frameCapacity: AVAudioFrameCount(data.count / MemoryLayout<Int16>.size)
    ) else {
      throw VoiceAudioError.unsupportedOutputFormat
    }
    buffer.frameLength = buffer.frameCapacity
    let destination = buffer.audioBufferList.pointee.mBuffers
    guard let destinationData = destination.mData else {
      throw VoiceAudioError.unsupportedOutputFormat
    }
    data.withUnsafeBytes { bytes in
      guard let source = bytes.baseAddress else { return }
      memcpy(destinationData, source, data.count)
    }
    playerNode.scheduleBuffer(buffer)
    if !playerNode.isPlaying { playerNode.play() }
  }

  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let values = notification.userInfo,
          let rawType = values[AVAudioSessionInterruptionTypeKey] as? UInt,
          AVAudioSession.InterruptionType(rawValue: rawType) == .began else {
      return
    }
    serialQueue.async { [weak self] in
      self?.stopCaptureLocked()
      self?.playerNode.stop()
    }
  }

  @objc private func handleRouteChange(_ notification: Notification) {
    guard let values = notification.userInfo,
          let rawReason = values[AVAudioSessionRouteChangeReasonKey] as? UInt,
          AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable else {
      return
    }
    serialQueue.async { [weak self] in self?.playerNode.stop() }
  }
}

private enum VoiceAudioError: LocalizedError {
  case unsupportedInputFormat
  case unsupportedOutputFormat

  var errorDescription: String? {
    switch self {
    case .unsupportedInputFormat:
      return "This device does not support the required microphone PCM format."
    case .unsupportedOutputFormat:
      return "This device does not support the required speaker PCM format."
    }
  }
}
