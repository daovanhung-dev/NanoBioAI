import 'package:nano_app/core/constants/onboarding_constants.dart';

/// Selectable gender values for new onboarding profiles.
///
/// `OnboardingCatalog.genders` intentionally remains backward-compatible with
/// older persisted snapshots that may contain `other`; new onboarding input is
/// limited to the two product-supported values below.
const List<OnboardingChoiceOption> onboardingGenderOptions = [
  OnboardingChoiceOption(code: 'male', label: 'Nam', emoji: '👨'),
  OnboardingChoiceOption(code: 'female', label: 'Nữ', emoji: '👩'),
];
