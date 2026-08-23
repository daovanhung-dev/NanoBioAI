# Image Picker Service

Lifecycle: `Current source note`. Baseline: `25018e8`.

## Runtime status

- Camera selection is `Implemented/Partial`: lifestyle-schedule proof capture
  calls `pickFromCameraWithPermissionFeedback()` through
  `ScheduleProofImageService`.
- Gallery selection and generic avatar save helpers exist, but no reachable
  caller was confirmed at this baseline; treat those methods as `Source-only`.

## Service contract

`ImagePickerService` supports:

- Camera selection, including a variant that reports permission failure.
- Gallery selection.
- PNG/JPG/JPEG extension and 5 MB size validation.
- Picker resize hints up to 1920 × 1920 at quality 85.
- Copying a selected image into an app-documents subdirectory.
- Typed `ImagePickerServiceException` for pick/save/permission failures.

The runtime schedule-proof flow adds stronger processing in
`ScheduleProofImageService`: decode, bake orientation, resize, clear EXIF,
re-encode JPEG, validate size and save under `schedule_proofs/`.

## Important distinctions

- `pickFromCamera()` preserves the legacy `null` result for denied permission.
- `pickFromCameraWithPermissionFeedback()` throws a typed permission error so
  schedule UI can explain the next action.
- Picker resize parameters are not proof that an arbitrary file was normalized;
  schedule proof normalization happens in `ScheduleProofImageService`.
- `saveImageLocally()` defaults to `avatars/avatar_<timestamp>`, but that
  default does not prove an active avatar feature.

Platform camera/photo permissions are declared, but permission and camera
behavior still require device verification.
