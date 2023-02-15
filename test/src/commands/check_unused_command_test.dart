import 'dart:io' show Platform;

import 'package:file/memory.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../mocks/mocks.dart';

void main() {
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
        final mfs = MemoryFileSystem.test(
          style: Platform.isWindows
              ? FileSystemStyle.windows
              : FileSystemStyle.posix,
        );
        <String, String>{
          p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
          p.join('lib', 'main.dart'): mainFileContent,
          'l10n.yaml': l10nFileContent,
        }.forEach(
          (final path, final content) => mfs.file(path)
            ..createSync(recursive: true)
            ..writeAsStringSync(content),
        );

        final logger = MockLogger();
        final exitCode = await L10nizationCliCommandRunner(
          logger: logger,
          fileSystem: mfs,
        ).run(
          [CheckUnusedCommand.commandName],
        );

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
        final mfs = MemoryFileSystem.test(
          style: Platform.isWindows
              ? FileSystemStyle.windows
              : FileSystemStyle.posix,
        );
        <String, String>{
          p.join('lib', 'l10n', 'arb', 'app_en.arb'): arbFileContentSimple,
          p.join('lib', 'main.dart'): mainFileContent,
          'l10n.yaml': l10nFileContent,
        }.forEach(
          (final path, final content) => mfs.file(path)
            ..createSync(recursive: true)
            ..writeAsStringSync(content),
        );

        final logger = MockLogger();
        final exitCode = await L10nizationCliCommandRunner(
          logger: logger,
          fileSystem: mfs,
        ).run(
          [CheckUnusedCommand.commandName],
        );

        verifyNever(() => logger.info('a'));
        verifyNever(() => logger.info('b'));
        verify(() => logger.info('c')).called(1);
        verifyNever(() => logger.info('d'));

        expect(exitCode, 1);
      });

      test('with --root', () async {
        final mfs = MemoryFileSystem.test(
          style: Platform.isWindows
              ? FileSystemStyle.windows
              : FileSystemStyle.posix,
        );
        <String, String>{
          p.join('my_app', 'lib', 'l10n', 'arb', 'app_en.arb'):
              arbFileContentSimple,
          p.join('my_app', 'lib', 'main.dart'): mainFileContent,
          p.join('my_app', 'l10n.yaml'): l10nFileContent,
        }.forEach(
          (final path, final content) => mfs.file(path)
            ..createSync(recursive: true)
            ..writeAsStringSync(content),
        );

        final logger = MockLogger();
        final exitCode = await L10nizationCliCommandRunner(
          logger: logger,
          fileSystem: mfs,
        ).run(
          [
            CheckUnusedCommand.commandName,
            '--root',
            'my_app',
          ],
        );

        verifyNever(() => logger.info('a'));
        verifyNever(() => logger.info('b'));
        verify(() => logger.info('c')).called(1);
        verifyNever(() => logger.info('d'));

        expect(exitCode, 1);
      });
    });
  });
}
