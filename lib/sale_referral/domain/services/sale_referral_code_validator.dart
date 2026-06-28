class SaleReferralCodeValidator {
  const SaleReferralCodeValidator();

  static final _allowed = RegExp(r'^[A-Z0-9-]{4,32}$');

  String normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  String? validate(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return null;
    if (!_allowed.hasMatch(normalized)) {
      return 'Ma gioi thieu chi gom chu cai, so va dau gach ngang.';
    }
    return null;
  }
}
