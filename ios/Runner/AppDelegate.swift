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
  struct FrameResult {
    let eventType: String
    let confidence: Double
    let relativeEnergy: Double
    let baselineDelta: Double
  }

  private var sensitivity: String
  private var noiseFloor: Double?
  private var calibrationStartedAt: Date?
  private var calibrationSeconds: TimeInterval = 30
  private var calibrationEnergySum = 0.0
  private var calibrationFrames = 0
  private var repeatedHighEnergyFrames = 0

  init(sensitivity: String, initialNoiseFloor: Double?, calibrationSeconds: Int) {
    self.sensitivity = sensitivity
    self.noiseFloor = initialNoiseFloor
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
    calibrationEnergySum = 0
    calibrationFrames = 0
    repeatedHighEnergyFrames = 0
  }

  func isCalibrating() -> Bool {
    calibrationStartedAt != nil
  }

  func process(buffer: AVAudioPCMBuffer) -> (FrameResult?, Double?, Double?) {
    guard let channel = buffer.floatChannelData?[0] else { return (nil, nil, nil) }
    let count = Int(buffer.frameLength)
    guard count > 0 else { return (nil, nil, nil) }

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
    let rms = sqrt(sumSquares / Double(count))
    let zeroCrossingRate = Double(zeroCrossings) / Double(count)

    if let started = calibrationStartedAt {
      calibrationEnergySum += rms
      calibrationFrames += 1
      let elapsed = Date().timeIntervalSince(started)
      let progress = min(1.0, elapsed / calibrationSeconds)
      if progress >= 1.0 {
        let floor = max(0.000_1, calibrationEnergySum / Double(max(1, calibrationFrames)))
        noiseFloor = floor
        calibrationStartedAt = nil
        return (nil, progress, floor)
      }
      return (nil, progress, nil)
    }

    guard let baseline = noiseFloor, baseline > 0 else { return (nil, nil, nil) }
    let relative = rms / baseline
    let delta = max(0, rms - baseline)
    let candidateFloor: Double
    switch sensitivity {
    case "low": candidateFloor = 4.0
    case "high": candidateFloor = 2.2
    default: candidateFloor = 2.9
    }
    guard relative >= candidateFloor || peak >= 0.88 else {
      repeatedHighEnergyFrames = max(0, repeatedHighEnergyFrames - 1)
      return (nil, nil, nil)
    }

    repeatedHighEnergyFrames += 1
    let peakRatio = peak / max(rms, 0.0005)
    let eventType: String
    if peakRatio >= 3.6 && peak >= 0.82 {
      eventType = "strongImpact"
    } else if relative >= candidateFloor * 1.8 && zeroCrossingRate >= 0.20 {
      eventType = "abnormalScream"
    } else if relative >= candidateFloor * 1.45 && zeroCrossingRate >= 0.10 {
      eventType = "abnormalShout"
    } else if repeatedHighEnergyFrames >= 3 {
      eventType = "repeatedSuspiciousPattern"
    } else if relative >= candidateFloor * 1.25 {
      eventType = "suddenLoudSound"
    } else {
      eventType = "unknownHighEnergyEvent"
    }
    let confidence = min(0.97, 0.50 + relative / 12.0 + peak / 8.0)
    return (
      FrameResult(
        eventType: eventType,
        confidence: confidence,
        relativeEnergy: relative,
        baselineDelta: delta
      ),
      nil,
      nil
    )
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
    guard active, !detectionSuppressed else { return }
    let output = detector?.process(buffer: buffer)
    if let progress = output?.1 {
      emit("calibrationProgress", data: ["progress": progress])
    }
    if let floor = output?.2 {
      phase = "monitoring"
      emit("calibrationCompleted", data: ["noiseFloor": floor])
      emit("monitoringReady")
    }
    guard let candidate = output?.0 else { return }

    let energyFloor: Double
    let confidenceFloor: Double
    switch sensitivity {
    case "low":
      energyFloor = 4.4
      confidenceFloor = 0.78
    case "high":
      energyFloor = 2.5
      confidenceFloor = 0.58
    default:
      energyFloor = 3.2
      confidenceFloor = 0.66
    }
    guard candidate.relativeEnergy >= energyFloor,
          candidate.confidence >= confidenceFloor else { return }
    beginAlert(candidate)
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
      "severity": candidate.relativeEnergy >= 6.0 ? "high" : "attention",
      "confidence": candidate.confidence,
      "relativeEnergy": candidate.relativeEnergy,
      "baselineDelta": candidate.baselineDelta,
      "repetitionCount": 1,
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
