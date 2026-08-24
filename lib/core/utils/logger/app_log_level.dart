enum AppLogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal;

  String get label => switch (this) {
    AppLogLevel.trace => 'TRACE',
    AppLogLevel.debug => 'DEBUG',
    AppLogLevel.info => 'INFO',
    AppLogLevel.warn => 'WARN',
    AppLogLevel.error => 'ERROR',
    AppLogLevel.fatal => 'FATAL',
  };
}
