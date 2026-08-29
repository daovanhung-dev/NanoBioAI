# Foreground microphone declaration

The Android manifest declares `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_MICROPHONE` and `RECORD_AUDIO` for the Sleep Safety
monitor. The feature shows an in-app disclosure, starts only after an explicit
user action and a granted microphone permission, and keeps a visible ongoing
notification while the native foreground service is active. Reminder
notifications only bring the user back to the app; they do not start the
microphone in the background. Raw audio is not sent to an AI provider by the
Flutter contract; verify the native implementation on-device.

The Play declaration should describe this as user-enabled health/safety
monitoring, not diagnosis, treatment or emergency response.

Status: OPEN — manually verify on a target Android 14+ device and complete the
Play Console foreground-service declaration. Static manifest presence is not a
runtime permission or policy approval.
