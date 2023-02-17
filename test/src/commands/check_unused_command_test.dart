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
    group('when 0 translation is unused then success code', () {
      const l10nFileContent = '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb''';

      const arbFileContentSimple = '''
{
  "@@locale": "en",
  "a": "a"
}''';

      const mainFileContent = '''
void main() {
  AppLocalizations.of(context).a;
}''';

      test('with --root', () async {
        <String, String>{
          p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
          p.join('lib', 'main.dart'): mainFileContent,
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

    group('when 1 translation is unused then error code', () {
      const l10nFileContent = '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb''';

      const arbFileContentSimple = '''
{
  "@@locale": "en",
  "a": "a",
  "b": "b",
  "c": "c",
  "d": "d"
}''';

      const mainFileContent = '''
void main() {
  AppLocalizations.of(context).a;
  AppLocalizations.of(context).a;
  l10n.b;
  Stuff().c;
  context.l10n.d;
}''';

      test('without --root', () async {
        <String, String>{
          p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
          p.join('lib', 'main.dart'): mainFileContent,
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
        verify(() => logger.info('c')).called(1);
        verifyNever(() => logger.info('d'));

        expect(exitCode, 1);
      });

      test('with --root', () async {
        <String, String>{
          p.join('my_app', 'lib', 'l10n', 'arb', 'app_en.arb'):
              arbFileContentSimple,
          p.join('my_app', 'lib', 'main.dart'): mainFileContent,
          p.join('my_app', 'l10n.yaml'): l10nFileContent,
        }.forEach(
          (final path, final content) => fileSystem.file(path)
            ..createSync(recursive: true)
            ..writeAsStringSync(content),
        );

        final exitCode = await commandRunner.run([
          CheckUnusedCommand.commandName,
          '--root',
          'my_app',
        ]);

        verifyNever(() => logger.info('a'));
        verifyNever(() => logger.info('b'));
        verify(() => logger.info('c')).called(1);
        verifyNever(() => logger.info('d'));

        expect(exitCode, 1);
      });
    });

    group(
        '''when 0 translation by extension of AppLocalizations is unused then success code''',
        () {
      const l10nFileContent = '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb''';

      const arbFileContentSimple = '''
{
  "@@locale": "en",
  "a": "a"
}''';

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

      test('with --root', () async {
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
    });
  });
}
