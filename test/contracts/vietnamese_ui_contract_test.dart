import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production-owned UI copy has no known localization regressions', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => _isUserFacingSource(_normalize(file.path)))
        .toList(growable: false);

    final violations = <String>[];
    for (final file in files) {
      final path = _normalize(file.path);
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.trimLeft().startsWith('//')) continue;
        for (final rule in _forbiddenUiCopy.entries) {
          if (rule.value.hasMatch(line)) {
            violations.add('$path:${index + 1}: ${rule.key}');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('new task and reward surfaces sanitize system-owned dynamic copy', () {
    final schedulePage = File(
      'lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart',
    ).readAsStringSync();
    final proofGallery = File(
      'lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart',
    ).readAsStringSync();
    final reminderService = File(
      'lib/app_versions/v1/services/notifications/reminder_schedule_service.dart',
    ).readAsStringSync();
    final rewardPage = File(
      'lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart',
    ).readAsStringSync();
    final adminPanel = File(
      'lib/app_versions/admin/features/wellness_rewards/presentation/admin_wellness_rewards_panel.dart',
    ).readAsStringSync();

    expect(schedulePage, contains('vietnameseSystemUiText('));
    expect(proofGallery, contains('vietnameseSystemUiText('));
    expect(proofGallery, isNot(contains('Text(error.message)')));
    expect(reminderService, contains('vietnameseSystemUiText('));
    expect(reminderService, isNot(contains('Mở app')));
    expect(rewardPage, contains('_redemptionStatusLabel(entry.status)'));
    expect(adminPanel, contains('final safeMessage = vietnameseSystemUiText('));
  });
}

bool _isUserFacingSource(String path) {
  if (path.endsWith('/dev_database_viewer_page.dart')) return false;
  if (path.contains('/l10n/app_localizations')) return false;
  if (path.endsWith('/shared/widgets/vietnamese_ui_text.dart')) return false;

  return path.contains('/presentation/pages/') ||
      path.contains('/presentation/widgets/') ||
      path.contains('/presentation/constants/') ||
      path.endsWith(
        '/features/wellness_rewards/presentation/admin_wellness_rewards_panel.dart',
      ) ||
      path.contains('/app/bio_ai_') ||
      path.endsWith('/services/supabase/sale/sale_terms.dart') ||
      path.endsWith('/services/image_picker/image_picker_service.dart') ||
      path.endsWith('/core/membership/membership_display_info.dart');
}

String _normalize(String path) => path.replaceAll('\\', '/');

final _forbiddenUiCopy = <String, RegExp>{
  'mojibake': RegExp(r'(?:Ã|Â|Ä|Æ)[\u0080-\u00BF]|áº|á»|â€™|â€œ|â€|ï¿½|�'),
  'known English UI copy': RegExp(
    r'\b(?:Please|Welcome|Invalid image|Failed to|Sign in|Log in|English|Dark mode|Light mode)\b',
    caseSensitive: false,
  ),
  'known unaccented Vietnamese UI copy': RegExp(
    r'''["'](?:Dang mo|Da khoa|Nhap ma|Ma gioi thieu|Vui long|Chua co|Khong |Tai khoan|Nguoi dung|Thong tin|Nhiem vu|Suc khoe)''',
  ),
  'legacy English product labels': RegExp(
    r'''["'](?:Gói Free|NanoBio Admin|Đang (?:bật|tắt) nhắc nhở local|[^"']*(?:Nabi chat|lịch sử chat|mở chat))''',
    caseSensitive: false,
  ),
  'raw internal terminology in a UI literal': RegExp(
    r'''["'][^"']*\b(?:stack trace|exception|database table|RPC get_|role Admin)\b''',
    caseSensitive: false,
  ),
  'internal formula version rendered by presentation': RegExp(
    r'\bformulaVersion\b',
  ),
  'raw exception message rendered by presentation': RegExp(
    r'Text\(\s*error\.message\s*\)',
  ),
};
