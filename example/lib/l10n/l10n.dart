import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String byKey(final String value) {
    switch (value) {
      case 'helloMars':
        return helloMars;
      default:
        throw Exception();
    }
  }
}
