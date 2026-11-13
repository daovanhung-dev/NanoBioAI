import 'web_runtime_support_stub.dart'
    if (dart.library.js_interop) 'web_runtime_support_web.dart'
    as platform;

bool get isSecureCrossOriginIsolated => platform.isSecureCrossOriginIsolated;
