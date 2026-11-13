import 'package:web/web.dart' as web;

bool get isSecureCrossOriginIsolated =>
    web.window.isSecureContext && web.window.crossOriginIsolated;
