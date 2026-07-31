import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/payments/viet_qr_payload_builder.dart';

void main() {
  test('builds the expected VietQR payload and CRC16 checksum', () {
    final payload = VietQrPayloadBuilder.build(
      bankBin: '970436',
      accountNumber: '1026806174',
      accountName: 'LE PHU THACH',
      amount: 399000,
      transferMemo: 'NB123ABC LE PHU THACH',
    );

    expect(
      payload,
      '00020101021238540010A0000007270124000697043601101026806174'
      '0208QRIBFTTA530370454063990005802VN5912LE PHU THACH'
      '62250821NB123ABC LE PHU THACH63049F78',
    );
  });

  test('keeps the transfer memo printable ASCII and at most 25 characters', () {
    final memo = VietQrPayloadBuilder.normalizeTransferMemo(
      'NB1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ !@#',
    );

    expect(memo, isNotNull);
    expect(memo!.length, VietQrPayloadBuilder.maxTransferMemoLength);
    expect(memo, matches(RegExp(r'^[A-Z0-9 ]+$')));
  });

  test('does not build a QR code from incomplete server details', () {
    expect(
      VietQrPayloadBuilder.build(
        bankBin: '970436',
        accountNumber: null,
        accountName: 'LE PHU THACH',
        amount: 399000,
        transferMemo: 'NB123ABC',
      ),
      isNull,
    );
  });
}
