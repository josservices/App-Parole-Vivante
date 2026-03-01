class AppConfig {
  static const bool licenseOk = bool.fromEnvironment(
    'LICENSE_OK',
    defaultValue: false,
  );
}
