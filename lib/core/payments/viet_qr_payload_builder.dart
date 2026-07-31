/// Builds EMVCo/VietQR-compatible transfer payloads from server-supplied
/// beneficiary details. It intentionally contains no bank configuration.
class VietQrPayloadBuilder {
  static const int maxTransferMemoLength = 25;
  static const int maxAccountNameLength = 25;

  const VietQrPayloadBuilder._();

  /// Returns a QR payload when all required, server-supplied values are
  /// available. A missing value returns null instead of creating a QR code
  /// that could direct a payment with incomplete information.
  static String? build({
    required String? bankBin,
    required String? accountNumber,
    required String? accountName,
    required int amount,
    required String? transferMemo,
  }) {
    final normalizedBankBin = _requiredText(bankBin);
    final normalizedAccountNumber = _requiredText(accountNumber);
    final normalizedAccountName = normalizeAccountName(accountName);
    final normalizedMemo = normalizeTransferMemo(transferMemo);
    if (normalizedBankBin == null ||
        normalizedAccountNumber == null ||
        normalizedAccountName == null ||
        normalizedMemo == null ||
        amount <= 0) {
      return null;
    }

    final beneficiary =
        _emv('00', normalizedBankBin) + _emv('01', normalizedAccountNumber);
    final merchantAccount =
        '${_emv('00', 'A000000727')}'
        '${_emv('01', beneficiary)}'
        '${_emv('02', 'QRIBFTTA')}';
    final additionalData = _emv('08', normalizedMemo);
    final raw =
        '${_emv('00', '01')}'
        '${_emv('01', '12')}'
        '${_emv('38', merchantAccount)}'
        '${_emv('53', '704')}'
        '${_emv('54', amount.toString())}'
        '${_emv('58', 'VN')}'
        '${_emv('59', normalizedAccountName)}'
        '${_emv('62', additionalData)}'
        '6304';
    return '$raw${crc16Ccitt(raw)}';
  }

  /// VietQR/NAPAS transfer content is limited to printable ASCII in this
  /// product flow. The backend owns the canonical memo; this is a defensive
  /// client-side safeguard before encoding it into a QR payload.
  static String? normalizeTransferMemo(String? value) {
    return _ascii(value, maxLength: maxTransferMemoLength);
  }

  static String? normalizeAccountName(String? value) {
    return _ascii(value, maxLength: maxAccountNameLength);
  }

  static String crc16Ccitt(String input) {
    var crc = 0xFFFF;
    for (final unit in input.codeUnits) {
      crc ^= unit << 8;
      for (var index = 0; index < 8; index++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String _emv(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  static String? _requiredText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _ascii(String? value, {required int maxLength}) {
    final normalized = value
        ?.toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.length <= maxLength
        ? normalized
        : normalized.substring(0, maxLength);
  }
}
