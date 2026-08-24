import AVFoundation
import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

private enum SleepSafetyIOSConstants {
  static let controlChannel = "com.nanobioai.app/sleep_safety/control"
  static let eventChannel = "com.nanobioai.app/sleep_safety/events"
  static let notificationCategory = "nanobio_sleep_safety_alert"
  static let notificationPrefix = "nanobio.sleep_safety."
  static let actionOK = "sleep_safety_ok"
  static let actionHelp = "sleep_safety_help"
}

private final class SleepSafetyIOSDetector {
  struct AudioMetrics {
    let signalLevel: Double
    let peakLevel: Double
    let relativeEnergy: Double
    let baselineLevel: Double
    let phase: String
  }

  struct FrameResult {
    let eventType: String
    let confidence: Double
    let relativeEnergy: Double
    let baselineDelta: Double
    let repetitionCount: Int
  }

  struct ProcessOutput {
    let event: FrameResult?
    let candidateType: String?
    let metrics: AudioMetrics
    let calibrationProgress: Double?
    let completedNoiseFloor: Double?
  }

  private struct Thresholds {
    let relative: Double
    let minimumRms: Double
    let extremeRms: Double
    let extremePeak: Double
  }

  private var sensitivity: String
  private var noiseFloor: Double
  private var calibrationStartedAt: Date?
  private var calibrationSeconds: TimeInterval = 30
  private var calibrationSamples: [Double] = []
  private var rollingRms: [Double] = []
  private var sustainedHighEnergyFrames = 0
  private var burstCount = 0
  private var lastBurstAt: Date?

  init(sensitivity: String, initialNoiseFloor: Double?, calibrationSeconds: Int) {
    self.sensitivity = sensitivity
    self.noiseFloor = max(0.0005, initialNoiseFloor ?? 0.006)
    self.calibrationSeconds = TimeInterval(max(10, min(calibrationSeconds, 60)))
    if initialNoiseFloor == nil {
      startCalibration(seconds: calibrationSeconds)
    }
  }

  func updateSensitivity(_ value: String) {
    sensitivity = value
  }

  func startCalibration(seconds: Int = 30) {
    calibrationStartedAt = Date()
    calibrationSeconds = TimeInterval(max(10, min(seconds, 60)))
    calibrationSamples.removeAll(keepingCapacity: true)
    rollingRms.removeAll(keepingCapacity: true)
    sustainedHighEnergyFrames = 0
    burstCount = 0
    lastBurstAt = nil
  }

  func isCalibrating() -> Bool {
    calibrationStartedAt != nil
  }

  func process(buffer: AVAudioPCMBuffer) -> ProcessOutput? {
    guard let channel = buffer.floatChannelData?[0] else { return nil }
    let count = Int(buffer.frameLength)
    guard count > 0 else { return nil }

    var sumSquares = 0.0
    var peak = 0.0
    var zeroCrossings = 0
    var previous = 0.0
    for index in 0..<count {
      let value = Double(channel[index])
      sumSquares += value * value
      peak = max(peak, abs(value))
      if index > 0 && ((previous < 0 && value >= 0) || (previous >= 0 && value < 0)) {
        zeroCrossings += 1
      }
      previous = value
    }

    let rms = max(0.000_001, sqrt(sumSquares / Double(count)))
    let zeroCrossingRate = Double(zeroCrossings) / Double(count)
    let baseline = calibrationStartedAt == nil ? noiseFloor : provisionalCalibrationFloor()
    let relative = rms / max(0.0005, baseline)
    let delta = max(0, rms - baseline)
    let peakRatio = peak / max(rms, 0.0005)
    let previousRolling = max(baseline, rollingAverage())
    let attackRatio = rms / max(0.0005, previousRolling)
    pushRollingRms(rms)

    if let started = calibrationStartedAt {
      calibrationSamples.append(rms)
      let elapsed = Date().timeIntervalSince(started)
      let progress = min(1.0, elapsed / calibrationSeconds)
      let bypass = calibrationSafetyBypass(
        rms: rms,
        peak: peak,
        relative: relative,
        zeroCrossingRate: zeroCrossingRate,
        peakRatio: peakRatio,
        attackRatio: attackRatio
      )

      var completedFloor: Double?
      if progress >= 1.0 && !calibrationSamples.isEmpty {
        noiseFloor = robustNoiseFloor(calibrationSamples)
        calibrationStartedAt = nil
        completedFloor = noiseFloor
      }

      return ProcessOutput(
        event: bypass,
        candidateType: bypass?.eventType,
        metrics: makeMetrics(
          rms: rms,
          peak: peak,
          relative: relative,
          baseline: baseline,
          phase: bypass == nil ? "calibrating" : "candidate"
        ),
        calibrationProgress: progress,
        completedNoiseFloor: completedFloor
      )
    }

    let thresholds = thresholdsForSensitivity()
    let isHighEnergy = relative >= thresholds.relative && rms >= thresholds.minimumRms
    if isHighEnergy {
      sustainedHighEnergyFrames = min(12, sustainedHighEnergyFrames + 1)
    } else {
      sustainedHighEnergyFrames = max(0, sustainedHighEnergyFrames - 1)
    }

    if relative < 1.65 && peak < 0.42 && rms < thresholds.minimumRms {
      noiseFloor = min(0.12, max(0.0005, noiseFloor * 0.996 + rms * 0.004))
    }

    let extreme = peak >= thresholds.extremePeak ||
      rms >= thresholds.extremeRms ||
      (rms >= thresholds.minimumRms * 1.7 && peak >= thresholds.extremePeak * 0.82)
    let impact = peak >= 0.72 && peakRatio >= 3.0 && attackRatio >= 2.0
    let vocalLike = zeroCrossingRate >= 0.055 && zeroCrossingRate <= 0.36
    let scream = vocalLike && sustainedHighEnergyFrames >= 2 &&
      relative >= thresholds.relative * 1.15 && rms >= thresholds.minimumRms
    let shout = sustainedHighEnergyFrames >= 2 &&
      relative >= thresholds.relative && rms >= thresholds.minimumRms
    let sudden = extreme ||
      (relative >= thresholds.relative * 1.35 && rms >= thresholds.minimumRms) ||
      (attackRatio >= 2.35 && relative >= thresholds.relative && rms >= thresholds.minimumRms)

    var candidateType: String?
    if impact {
      candidateType = "strongImpact"
    } else if scream {
      candidateType = "abnormalScream"
    } else if shout {
      candidateType = "abnormalShout"
    } else if sudden {
      candidateType = "suddenLoudSound"
    }

    if candidateType != nil {
      registerBurst()
    } else if let last = lastBurstAt, Date().timeIntervalSince(last) > 2.5 {
      burstCount = 0
    }

    let repeated = burstCount >= 3 &&
      (lastBurstAt.map { Date().timeIntervalSince($0) <= 2.5 } ?? false)
    let resolvedType: String?
    if impact {
      resolvedType = "strongImpact"
    } else if scream {
      resolvedType = "abnormalScream"
    } else if repeated {
      resolvedType = "repeatedSuspiciousPattern"
    } else if shout {
      resolvedType = "abnormalShout"
    } else if sudden {
      resolvedType = "suddenLoudSound"
    } else {
      resolvedType = nil
    }

    let confirmed: Bool
    if resolvedType == nil {
      confirmed = false
    } else if impact || extreme || repeated {
      confirmed = true
    } else if scream && sustainedHighEnergyFrames >= 2 {
      confirmed = true
    } else if shout && (sustainedHighEnergyFrames >= 3 || attackRatio >= 2.0) {
      confirmed = true
    } else if sudden && (relative >= thresholds.relative * 1.6 || attackRatio >= 2.6) {
      confirmed = true
    } else {
      confirmed = false
    }

    let confidence = confidenceScore(
      relative: relative,
      threshold: thresholds.relative,
      rms: rms,
      minimumRms: thresholds.minimumRms,
      peak: peak,
      attackRatio: attackRatio,
      sustainedFrames: sustainedHighEnergyFrames,
      extreme: extreme
    )

    let event: FrameResult?
    if confirmed, let resolvedType = resolvedType {
      event = FrameResult(
        eventType: resolvedType,
        confidence: confidence,
        relativeEnergy: relative,
        baselineDelta: delta,
        repetitionCount: max(1, burstCount)
      )
    } else {
      event = nil
    }

    return ProcessOutput(
      event: event,
      candidateType: resolvedType,
      metrics: makeMetrics(
        rms: rms,
        peak: peak,
        relative: relative,
        baseline: noiseFloor,
        phase: event != nil ? "alerting" : (resolvedType != nil ? "candidate" : "monitoring")
      ),
      calibrationProgress: nil,
      completedNoiseFloor: nil
    )
  }

  private func thresholdsForSensitivity() -> Thresholds {
    switch sensitivity {
    case "high":
      return Thresholds(relative: 1.9, minimumRms: 0.032, extremeRms: 0.12, extremePeak: 0.78)
    case "low":
      return Thresholds(relative: 3.1, minimumRms: 0.065, extremeRms: 0.20, extremePeak: 0.92)
    default:
      return Thresholds(relative: 2.35, minimumRms: 0.045, extremeRms: 0.15, extremePeak: 0.86)
    }
  }

  private func calibrationSafetyBypass(
    rms: Double,
    peak: Double,
    relative: Double,
    zeroCrossingRate: Double,
    peakRatio: Double,
    attackRatio: Double
  ) -> FrameResult? {
    let thresholds = thresholdsForSensitivity()
    let bypass = peak >= 0.92 ||
      rms >= max(0.18, thresholds.extremeRms) ||
      (rms >= max(0.075, thresholds.minimumRms) && peak >= 0.40 && relative >= 4.8)
    guard bypass else { return nil }

    let vocalLike = zeroCrossingRate >= 0.055 && zeroCrossingRate <= 0.36
    let eventType: String
    if peakRatio >= 3.2 && peak >= 0.82 {
      eventType = "strongImpact"
    } else if vocalLike && rms >= 0.10 {
      eventType = "abnormalScream"
    } else {
      eventType = "suddenLoudSound"
    }
    return FrameResult(
      eventType: eventType,
      confidence: min(0.98, 0.76 + min(0.20, attackRatio / 10.0)),
      relativeEnergy: relative,
      baselineDelta: max(0, rms - provisionalCalibrationFloor()),
      repetitionCount: 1
    )
  }

  private func robustNoiseFloor(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.006 }
    let sorted = values.sorted()
    let retainedCount = max(1, Int(Double(sorted.count) * 0.85))
    let retained = Array(sorted.prefix(retainedCount))
    let middle = retained.count / 2
    let median: Double
    if retained.count > 1 && retained.count % 2 == 0 {
      median = (retained[middle - 1] + retained[middle]) / 2.0
    } else {
      median = retained[middle]
    }
    let mean = retained.reduce(0, +) / Double(retained.count)
    return min(0.12, max(0.0005, median * 0.7 + mean * 0.3))
  }

  private func provisionalCalibrationFloor() -> Double {
    guard calibrationSamples.count >= 4 else { return max(0.006, noiseFloor) }
    return robustNoiseFloor(calibrationSamples)
  }

  private func registerBurst() {
    let now = Date()
    if let last = lastBurstAt, now.timeIntervalSince(last) <= 2.5 {
      burstCount = min(8, burstCount + 1)
    } else {
      burstCount = 1
    }
    lastBurstAt = now
  }

  private func pushRollingRms(_ value: Double) {
    rollingRms.append(value)
    if rollingRms.count > 12 {
      rollingRms.removeFirst(rollingRms.count - 12)
    }
  }

  private func rollingAverage() -> Double {
    guard !rollingRms.isEmpty else { return noiseFloor }
    return rollingRms.reduce(0, +) / Double(rollingRms.count)
  }

  private func confidenceScore(
    relative: Double,
    threshold: Double,
    rms: Double,
    minimumRms: Double,
    peak: Double,
    attackRatio: Double,
    sustainedFrames: Int,
    extreme: Bool
  ) -> Double {
    if extreme { return 0.95 }
    let relativeScore = min(1.0, max(0, relative / (threshold * 2.0)))
    let levelScore = min(1.0, max(0, rms / (minimumRms * 3.0)))
    let peakScore = min(1.0, max(0, peak / 0.90))
    let attackScore = min(1.0, max(0, attackRatio / 3.0))
    let persistenceScore = min(1.0, max(0, Double(sustainedFrames) / 4.0))
    return min(0.96, max(0,
      relativeScore * 0.32 +
      levelScore * 0.22 +
      peakScore * 0.16 +
      attackScore * 0.14 +
      persistenceScore * 0.16
    ))
  }

  private func makeMetrics(
    rms: Double,
    peak: Double,
    relative: Double,
    baseline: Double,
    phase: String
  ) -> AudioMetrics {
    AudioMetrics(
      signalLevel: amplitudeToLevel(rms),
      peakLevel: amplitudeToLevel(peak),
      relativeEnergy: min(50, max(0, relative)),
      baselineLevel: amplitudeToLevel(baseline),
      phase: phase
    )
  }

  private func amplitudeToLevel(_ amplitude: Double) -> Double {
    let safe = max(0.000_001, amplitude)
    let db = 20.0 * log10(safe)
    return min(1.0, max(0, (db + 56.0) / 52.0))
  }
}
private final class SleepSafetyIOSRuntime {
  static let shared = SleepSafetyIOSRuntime()

  private let audioEngine = AVAudioEngine()
  private let audioSession = AVAudioSession.sharedInstance()
  private let queue = DispatchQueue(label: "com.nanobioai.app.sleep_safety.audio", qos: .userInitiated)
  private var detector: SleepSafetyIOSDetector?
  private var eventSink: FlutterEventSink?
  private var currentEventID: String?
  private var currentEventData: [String: Any]?
  private var activeSessionID: String?
  private var detectionSuppressed = false
  private var sensitivity = "balanced"
  private var cooldownSeconds = 120
  private var scheduledEndWork: DispatchWorkItem?
  private var reminderWork: DispatchWorkItem?
  private var escalationWork: DispatchWorkItem?
  private var active = false
  private var phase = "idle"
  private var lastMetricsEmitAt = Date.distantPast
  private var lastCandidateEmitAt = Date.distantPast

  private init() {}

  func setEventSink(_ sink: FlutterEventSink?) {
    eventSink = sink
    if sink != nil {
      emit("statusSnapshot", data: statusSnapshot())
    }
  }

  func statusSnapshot() -> [String: Any] {
    [
      "active": active,
      "phase": phase,
      "sessionId": activeSessionID as Any,
      "eventId": currentEventID as Any,
      "currentEvent": currentEventData as Any,
    ]
  }

  func start(arguments: [String: Any], result: @escaping FlutterResult) {
    guard !active else { result(nil); return }
    guard audioSession.recordPermission == .granted else {
      emit("permissionLost")
      result(FlutterError(code: "microphone_permission", message: "Microphone permission is required.", details: nil))
      return
    }

    do {
      activeSessionID = arguments["sessionId"] as? String
      sensitivity = (arguments["sensitivity"] as? String) ?? "balanced"
      cooldownSeconds = max(30, min((arguments["cooldownSeconds"] as? NSNumber)?.intValue ?? 120, 900))
      let calibrationSeconds = max(10, min((arguments["calibrationSeconds"] as? NSNumber)?.intValue ?? 30, 60))
      let calibrationRequired = (arguments["calibrationRequired"] as? Bool) ?? true
      let storedFloor = (arguments["calibrationNoiseFloor"] as? NSNumber)?.doubleValue
      let initialFloor = calibrationRequired ? nil : storedFloor
      detector = SleepSafetyIOSDetector(
        sensitivity: sensitivity,
        initialNoiseFloor: initialFloor,
        calibrationSeconds: calibrationSeconds
      )

      try audioSession.setCategory(
        .playAndRecord,
        mode: .measurement,
        options: [.defaultToSpeaker, .allowBluetooth]
      )
      try audioSession.setActive(true, options: [])

      let input = audioEngine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
        self?.queue.async { self?.process(buffer: buffer) }
      }
      audioEngine.prepare()
      try audioEngine.start()

      lastMetricsEmitAt = Date.distantPast
      lastCandidateEmitAt = Date.distantPast
      active = true
      phase = detector?.isCalibrating() == true ? "calibrating" : "monitoring"
      emit("serviceStarted")
      if phase == "monitoring" { emit("monitoringReady") }
      scheduleAutoStop(arguments["scheduledEndEpochMs"])
      result(nil)
    } catch {
      stop(reason: "native_start_failure")
      emit("nativeFailure", data: ["code": "ios_audio_start_failed"])
      result(FlutterError(code: "audio_start_failed", message: "Unable to start sleep safety audio session.", details: nil))
    }
  }

  func stop(reason: String) {
    cancelAlertTimers()
    scheduledEndWork?.cancel()
    scheduledEndWork = nil
    if audioEngine.isRunning { audioEngine.stop() }
    audioEngine.inputNode.removeTap(onBus: 0)
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    detector = nil
    currentEventID = nil
    currentEventData = nil
    activeSessionID = nil
    detectionSuppressed = false
    active = false
    phase = "idle"
    lastMetricsEmitAt = Date.distantPast
    lastCandidateEmitAt = Date.distantPast
    emit("serviceStopped", data: ["reason": reason])
  }

  func startCalibration() {
    guard active else { return }
    detector?.startCalibration(seconds: 30)
    phase = "calibrating"
  }

  func update(arguments: [String: Any]) {
    if let value = arguments["sensitivity"] as? String {
      sensitivity = value
      detector?.updateSensitivity(value)
    }
    if let seconds = (arguments["cooldownSeconds"] as? NSNumber)?.intValue {
      cooldownSeconds = max(30, min(seconds, 900))
    }
  }

  func respond(eventID: String?, response: String) {
    guard let current = currentEventID else { return }
    if let eventID, eventID != current { return }
    cancelAlertTimers()
    currentEventData?["response"] = response
    emit("userResponse", data: ["eventId": current, "response": response])
    if response == "need_help" {
      phase = "escalating"
      emit("escalationRequired", data: ["eventId": current])
      return
    }
    currentEventID = nil
    currentEventData = nil
    phase = "cooldown"
    queue.asyncAfter(deadline: .now() + .seconds(cooldownSeconds)) { [weak self] in
      guard let self, self.active else { return }
      self.detectionSuppressed = false
      self.phase = "monitoring"
      self.emit("monitoringReady")
    }
  }

  func handlesNotificationResponse(_ response: UNNotificationResponse) -> Bool {
    guard response.notification.request.identifier.hasPrefix(SleepSafetyIOSConstants.notificationPrefix) else {
      return false
    }
    let eventID = response.notification.request.content.userInfo["event_id"] as? String
    switch response.actionIdentifier {
    case SleepSafetyIOSConstants.actionHelp:
      respond(eventID: eventID, response: "need_help")
    case SleepSafetyIOSConstants.actionOK:
      respond(eventID: eventID, response: "ok")
    default:
      // Tapping the body intentionally leaves the safety timer active; Flutter
      // will present the in-app overlay from the already emitted event state.
      break
    }
    return true
  }

  private func process(buffer: AVAudioPCMBuffer) {
    guard active, let output = detector?.process(buffer: buffer) else { return }

    let now = Date()
    if now.timeIntervalSince(lastMetricsEmitAt) >= 0.16 {
      lastMetricsEmitAt = now
      emit("audioMetrics", data: [
        "signalLevel": output.metrics.signalLevel,
        "peakLevel": output.metrics.peakLevel,
        "relativeEnergy": output.metrics.relativeEnergy,
        "baselineLevel": output.metrics.baselineLevel,
        "phase": detectionSuppressed ? phase : output.metrics.phase,
        "capturedAtEpochMs": Int64(now.timeIntervalSince1970 * 1000.0),
      ])
    }

    if let progress = output.calibrationProgress {
      emit("calibrationProgress", data: ["progress": progress])
    }
    if let floor = output.completedNoiseFloor {
      let canBecomeReady = !detectionSuppressed && phase == "calibrating"
      if canBecomeReady { phase = "monitoring" }
      emit("calibrationCompleted", data: ["noiseFloor": floor])
      if canBecomeReady { emit("monitoringReady") }
    }

    guard !detectionSuppressed else { return }

    if output.event == nil,
       let candidateType = output.candidateType,
       now.timeIntervalSince(lastCandidateEmitAt) >= 0.30 {
      lastCandidateEmitAt = now
      emit("detectorCandidate", data: [
        "eventType": candidateType,
        "relativeEnergy": output.metrics.relativeEnergy,
        "signalLevel": output.metrics.signalLevel,
      ])
    }

    if let event = output.event {
      beginAlert(event)
    }
  }

  private func beginAlert(_ candidate: SleepSafetyIOSDetector.FrameResult) {
    guard currentEventID == nil else { return }
    let eventID = UUID().uuidString
    currentEventID = eventID
    detectionSuppressed = true
    phase = "alerting"
    let formatter = ISO8601DateFormatter()
    let eventData: [String: Any] = [
      "eventId": eventID,
      "detectedAt": formatter.string(from: Date()),
      "eventType": candidate.eventType,
      "severity": (candidate.relativeEnergy >= 5.0 || candidate.confidence >= 0.90) ? "high" : "attention",
      "confidence": candidate.confidence,
      "relativeEnergy": candidate.relativeEnergy,
      "baselineDelta": candidate.baselineDelta,
      "repetitionCount": candidate.repetitionCount,
    ]
    currentEventData = eventData
    emit("confirmedSafetyEvent", data: eventData)
    postAlertNotification(eventID: eventID, reminder: false)

    let reminder = DispatchWorkItem { [weak self] in
      guard let self, self.currentEventID == eventID else { return }
      self.postAlertNotification(eventID: eventID, reminder: true)
      self.emit("alertReminder", data: ["eventId": eventID])
    }
    reminderWork = reminder
    DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: reminder)

    let escalation = DispatchWorkItem { [weak self] in
      guard let self, self.currentEventID == eventID else { return }
      self.phase = "escalating"
      self.emit("escalationRequired", data: ["eventId": eventID])
    }
    escalationWork = escalation
    DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: escalation)
  }

  private func postAlertNotification(eventID: String, reminder: Bool) {
    let content = UNMutableNotificationContent()
    content.title = "Bạn có ổn không?"
    content.body = reminder
      ? "Nabi vẫn chưa nhận được phản hồi. Hãy xác nhận nếu bạn ổn hoặc cần hỗ trợ."
      : "Nabi vừa nhận thấy một âm thanh cần được chú ý."
    content.sound = .default
    content.categoryIdentifier = SleepSafetyIOSConstants.notificationCategory
    content.userInfo = ["event_id": eventID]
    let request = UNNotificationRequest(
      identifier: SleepSafetyIOSConstants.notificationPrefix + eventID,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }

  private func scheduleAutoStop(_ rawEpoch: Any?) {
    scheduledEndWork?.cancel()
    guard let epoch = (rawEpoch as? NSNumber)?.int64Value, epoch > 0 else { return }
    let delay = TimeInterval(epoch) / 1000.0 - Date().timeIntervalSince1970
    guard delay > 0 else { return }
    let work = DispatchWorkItem { [weak self] in self?.stop(reason: "schedule_end") }
    scheduledEndWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
  }

  private func cancelAlertTimers() {
    reminderWork?.cancel()
    escalationWork?.cancel()
    reminderWork = nil
    escalationWork = nil
  }

  private func emit(_ type: String, data: [String: Any] = [:]) {
    let payload = ["type": type].merging(data) { _, new in new }
    DispatchQueue.main.async { [weak self] in self?.eventSink?(payload) }
  }
}

private final class SleepSafetyIOSChannelHandler: NSObject, FlutterStreamHandler {
  private let runtime = SleepSafetyIOSRuntime.shared
  private let control: FlutterMethodChannel
  private let events: FlutterEventChannel

  init(messenger: FlutterBinaryMessenger) {
    control = FlutterMethodChannel(
      name: SleepSafetyIOSConstants.controlChannel,
      binaryMessenger: messenger
    )
    events = FlutterEventChannel(
      name: SleepSafetyIOSConstants.eventChannel,
      binaryMessenger: messenger
    )
    super.init()
    events.setStreamHandler(self)
    control.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(nil); return }
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "startMonitoring":
        self.runtime.start(arguments: arguments, result: result)
      case "stopMonitoring":
        self.runtime.stop(reason: arguments["reason"] as? String ?? "user")
        result(nil)
      case "startCalibration":
        self.runtime.startCalibration()
        result(nil)
      case "updateRuntimeConfig":
        self.runtime.update(arguments: arguments)
        result(nil)
      case "respondToAlert":
        self.runtime.respond(
          eventID: arguments["eventId"] as? String,
          response: arguments["response"] as? String ?? "ok"
        )
        result(nil)
      case "getMonitoringStatus":
        result(self.runtime.statusSnapshot())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    runtime.setEventSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    runtime.setEventSink(nil)
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var sleepSafetyChannelHandler: SleepSafetyIOSChannelHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    let okAction = UNNotificationAction(
      identifier: SleepSafetyIOSConstants.actionOK,
      title: "Tôi ổn",
      options: []
    )
    let helpAction = UNNotificationAction(
      identifier: SleepSafetyIOSConstants.actionHelp,
      title: "Tôi cần hỗ trợ",
      options: [.foreground]
    )
    let category = UNNotificationCategory(
      identifier: SleepSafetyIOSConstants.notificationCategory,
      actions: [okAction, helpAction],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      sleepSafetyChannelHandler = SleepSafetyIOSChannelHandler(
        messenger: controller.binaryMessenger
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if SleepSafetyIOSRuntime.shared.handlesNotificationResponse(response) {
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier.hasPrefix(SleepSafetyIOSConstants.notificationPrefix) {
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound])
      } else {
        completionHandler([.alert, .sound])
      }
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }
}
