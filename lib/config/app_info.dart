import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static const appName = 'Zapiti App';

  const AppInfo._();

  static Future<String> versionLabel() async {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.isEmpty ? '' : '+${info.buildNumber}';
    return 'Versión ${info.version}$build';
  }
}

class AppLinks {
  static const privacyPolicy = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://yanfrisi.github.io/zapiti-privacy-policy/',
  );
  static const accountDeletion = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue: 'https://yanfrisi.github.io/zapiti-privacy-policy/#eliminar-cuenta',
  );
  static const linkedIn =
      'https://www.linkedin.com/in/juan-francisco-gutiérrez-vázquez-5b4294163';
  static const instagram = 'https://www.instagram.com/yanfrisi';

  const AppLinks._();
}
