import 'dart:io' show Platform;

import 'package:file/memory.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/mocks.dart';

const l10nFileContent = '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false''';

const arbFileContentSimple = '''
{
  "@@locale": "en",
  "helloWorld": "Hello World",
  "seeingTheWorldAgain": "Seeing the world again"
}''';

const appLocalizationsEnFileContent = '''
import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World';

  @override
  String get seeingTheWorldAgain => 'Seeing the world again';
}
''';

const appLocalizationsFileContent = r'''
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  String get helloWorld;

  String get seeingTheWorldAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}''';

const l10nDartFileContent = '''
export 'package:flutter_gen/gen_l10n/app_localizations.dart';''';

const mainFileContent = '''
import 'package:example/l10n/l10n.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _HomePage(),
      );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(final BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context).helloWorld),
              Text(AppLocalizations.of(context).helloWorld),
            ],
          ),
        ),
      );
}''';

void main() {
  group('check-unused', () {
    test('When l10n.yaml is right', () async {
      final logger = MockLogger();
      final mfs = MemoryFileSystem.test(
        style: Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix,
      );

      mfs.file(
        '.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart',
      )
        ..createSync(recursive: true)
        ..writeAsStringSync(appLocalizationsEnFileContent);

      mfs.file('.dart_tool/flutter_gen/gen_l10n/app_localizations.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(appLocalizationsFileContent);

      mfs.file('lib/l10n/arb/app_en.arb')
        ..createSync(recursive: true)
        ..writeAsStringSync(arbFileContentSimple);

      mfs.file('lib/l10n/l10n.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(l10nDartFileContent);

      mfs.file('lib/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(mainFileContent);

      mfs.file('l10n.yaml')
        ..createSync()
        ..writeAsStringSync(l10nFileContent);

      final commandRunner = L10nizationCliCommandRunner(
        logger: logger,
        fileSystem: mfs,
      );

      final exitCode = await commandRunner.run(
        [CheckUnusedCommand.commandName],
      );

      verifyNever(() => logger.info('helloWorld'));
      verify(() => logger.info('seeingTheWorldAgain')).called(1);
      verify(() => logger.success('Success')).called(1);

      expect(exitCode, ExitCode.success.code);
    });

    // PropertyAccessImpl (AppLocalizations.of(context).helloWorld)
    // MethodInvocationImpl (AppLocalizations.of(context))
    // SimpleIdentifierImpl (helloWorld)
  });
}
