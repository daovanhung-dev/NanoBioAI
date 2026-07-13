import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nano_app/l10n/app_localizations.dart';

/// Cấu hình ngôn ngữ dùng chung cho mọi bề mặt ứng dụng NanoBio.
///
/// Ứng dụng hiện chỉ phát hành giao diện tiếng Việt. Việc cố định locale giúp
/// các nhãn mặc định của Material, Cupertino và Widgets không phụ thuộc vào
/// ngôn ngữ của thiết bị.
abstract final class AppLocalizationConfig {
  static const locale = Locale('vi', 'VN');

  static const supportedLocales = <Locale>[Locale('vi', 'VN'), Locale('vi')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
