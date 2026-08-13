/// Builds the VietQR/NAPAS EMV payload from trusted server-supplied payment
/// details. No receiving-account or payment-reference configuration lives in
/// this class.
class VietQrPayloadBuilder {
  static const int maxTransferMemoLength = 25;
  static const int maxAccountNameLength = 25;
  static final RegExp _bankBinPattern = RegExp(r'^[0-9]{6}$');
  static final RegExp _accountNumberPattern = RegExp(r'^[0-9]{4,32}$');

  const VietQrPayloadBuilder._();

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
        !_bankBinPattern.hasMatch(normalizedBankBin) ||
        normalizedAccountNumber == null ||
        !_accountNumberPattern.hasMatch(normalizedAccountNumber) ||
        normalizedAccountName == null ||
        normalizedMemo == null ||
        amount <= 0) {
      return null;
    }

    // VietQR merchant-account information (ID 38):
    // 00 = NAPAS AID, 01 = consumer account information (BIN + account),
    // 02 = transfer service code QRIBFTTA.
    final consumerAccount =
        _emv('00', normalizedBankBin) +
        _emv('01', normalizedAccountNumber);
    final merchantAccount =
        _emv('00', 'A000000727') +
        _emv('01', consumerAccount) +
        _emv('02', 'QRIBFTTA');
    final additionalData = _emv('08', normalizedMemo);

    final withoutCrc =
        _emv('00', '01') +
        _emv('01', '12') +
        _emv('38', merchantAccount) +
        _emv('53', '704') +
        _emv('54', amount.toString()) +
        _emv('58', 'VN') +
        _emv('59', normalizedAccountName) +
        _emv('62', additionalData) +
        '6304';

    return '$withoutCrc${crc16Ccitt(withoutCrc)}';
  }

  static String? normalizeTransferMemo(String? value) {
    return _ascii(value, maxLength: maxTransferMemoLength);
  }

  static String? normalizeAccountName(String? value) {
    return _ascii(value, maxLength: maxAccountNameLength);
  }

  /// CRC-16/CCITT-FALSE used by EMV QR payloads.
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

  static bool hasValidCrc(String payload) {
    if (payload.length < 8 || !payload.contains('6304')) return false;
    final body = payload.substring(0, payload.length - 4);
    final checksum = payload.substring(payload.length - 4).toUpperCase();
    return RegExp(r'^[0-9A-F]{4}$').hasMatch(checksum) &&
        crc16Ccitt(body) == checksum;
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
