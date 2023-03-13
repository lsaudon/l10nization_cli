import 'dart:io' show Platform;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/check_unused/check_unused_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  late FileSystem fileSystem;
  late Logger logger;
  late L10nizationCliCommandRunner commandRunner;

  setUp(() {
    fileSystem = MemoryFileSystem.test(
      style:
          Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );
    logger = _MockLogger();
    commandRunner = L10nizationCliCommandRunner(
      logger: logger,
      fileSystem: fileSystem,
    );
  });

  group('check-unused', () {
    const l10nFileContent = '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb''';

    group(
      'complex dart file',
      () {
        const arbFileContentSimple = '''
{
  "@@locale": "en",
  "a": "a",
  "b": "b",
  "c": "c",
  "d": "d",
  "e": "e",
  "f": "f"
}''';

        const l10nDartFileContent = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsExtension on AppLocalizations {
  String byKey(final String value) {
    switch (value) {
      case 'd':
        return d;
      default:
        throw Exception();
    }
  }
}''';

        const mainDartFileContent = '''
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
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context).a),
            Text(AppLocalizations.of(context).a),
            Text(l10n.b),
            Text(Stuff().c),
            Text(context.l10n.f)
          ],
        ),
      ),
    );
  }
}

class Stuff {
  String get c => 'Seeing the world again';
}
''';

        test('current path', () async {
          <String, String>{
            p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
            p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
            p.join('lib', 'main.dart'): mainDartFileContent,
            'l10n.yaml': l10nFileContent,
          }.forEach(
            (final path, final content) => fileSystem.file(path)
              ..createSync(recursive: true)
              ..writeAsStringSync(content),
          );

          final exitCode =
              await commandRunner.run([CheckUnusedCommand.commandName]);

          verifyNever(() => logger.info('a'));
          verifyNever(() => logger.info('b'));
          verify(() => logger.info('c'));
          verifyNever(() => logger.info('d'));
          verify(() => logger.info('e'));
          verifyNever(() => logger.info('f'));

          expect(exitCode, ExitCode.usage.code);
        });

        test('with specific path', () async {
          <String, String>{
            p.join('example', 'lib', 'l10n', 'arb', 'app_en.arb'):
                arbFileContentSimple,
            p.join('example', 'lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
            p.join('example', 'lib', 'main.dart'): mainDartFileContent,
            p.join('example', 'l10n.yaml'): l10nFileContent,
          }.forEach(
            (final path, final content) => fileSystem.file(path)
              ..createSync(recursive: true)
              ..writeAsStringSync(content),
          );

          final exitCode = await commandRunner.run([
            CheckUnusedCommand.commandName,
            'example',
          ]);

          verifyNever(() => logger.info('a'));
          verifyNever(() => logger.info('b'));
          verify(() => logger.info('c'));
          verifyNever(() => logger.info('d'));
          verify(() => logger.info('e'));
          verifyNever(() => logger.info('f'));

          expect(exitCode, ExitCode.usage.code);
        });
      },
    );

    const arbFileContentSimple = '''
{
  "@@locale": "en",
  "a": "a"
}''';

    test('case in extension of AppLocalizations', () async {
      const l10nDartFileContent = '''
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String byKey(final String value) {
    switch (value) {
      case 'a':
        return a;
      default:
        throw Exception();
    }
  }
}
''';
      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case context.l10n.a', () async {
      const l10nDartFileContent = '''
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}''';

      const mainDartFileContent = '''
@override
Widget build(final BuildContext context) {
  return Text(context.l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case context.i18n.a', () async {
      const l10nDartFileContent = '''
extension AppLocalizationsX on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this);
}''';

      const mainDartFileContent = '''
@override
Widget build(final BuildContext context) {
  return Text(context.i18n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('BuildContext extension without AppLocalizations method', () async {
      const l10nDartFileContent = '''
extension AppLocalizationsX on BuildContext {
  Stuff get l10n => Stuff.of(this);
}''';

      const mainDartFileContent = '''
@override
Widget build(final BuildContext context) {
  return Text(context.l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verify(() => logger.info('a'));

      expect(exitCode, ExitCode.usage.code);
    });

    test('case l10n = context.l10n', () async {
      const l10nDartFileContent = '''
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}''';

      const mainDartFileContent = '''
@override
Widget build(final BuildContext context) {
  final l10n = context.l10n;
  return Text(l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case i18n = context.i18n', () async {
      const l10nDartFileContent = '''
extension AppLocalizationsX on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this);
}''';

      const mainDartFileContent = '''
@override
Widget build(final BuildContext context) {
  final i18n = context.i18n;
  return Text(i18n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'l10n', 'l10n.dart'): l10nDartFileContent,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case l10n.a', () async {
      const mainDartFileContent = '''
Widget build(final BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return Text(l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('variable of AppLocalizations create in other build', () async {
      const mainDartFileContent = '''
Widget build(final BuildContext context) {
  final l10n = AppLocalizations.of(context);
}

Widget build(final BuildContext context) {
  return Text(l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verify(() => logger.info('a'));

      expect(exitCode, ExitCode.usage.code);
    });

    test('case i18n.a', () async {
      const mainDartFileContent = '''
Widget build(final BuildContext context) {
  final i18n = AppLocalizations.of(context);
  return Text(i18n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case AppLocalizations is a field of class', () async {
      const mainDartFileContent = '''
class MyWidget extends StatelessWidget {
  const MyWidget({
    required this.l10n,
    super.key,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Text(l10n.a);
  }
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case AppLocalizations.of(context).a', () async {
      const mainDartFileContent = '''
Widget build(final BuildContext context) {
  return Text(AppLocalizations.of(context).a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case l10n is a parameter of a function', () async {
      const mainDartFileContent = '''
Widget build(final AppLocalizations l10n) {
  return Text(l10n.a);
}
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });

    test('case l10n is a parameter of a expression', () async {
      const mainDartFileContent = '''
Widget build(final AppLocalizations l10n) => Text(l10n.a);
''';

      <String, String>{
        p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
        p.join('lib', 'main.dart'): mainDartFileContent,
        'l10n.yaml': l10nFileContent,
      }.forEach(
        (final path, final content) => fileSystem.file(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(content),
      );

      final exitCode =
          await commandRunner.run([CheckUnusedCommand.commandName]);

      verifyNever(() => logger.info('a'));

      expect(exitCode, ExitCode.success.code);
    });
  });
}
