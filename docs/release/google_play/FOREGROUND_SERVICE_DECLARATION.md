# Foreground microphone declaration

The Android manifest declares `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_MICROPHONE` and `RECORD_AUDIO` for the sleep safety
monitor. The declaration must describe the user-started, health-related
microphone use and the visible notification shown while recording.

Status: OPEN — manually verify on a target Android 14+ device and complete the
Play Console foreground-service declaration. Static manifest presence is not a
runtime permission or policy approval.

