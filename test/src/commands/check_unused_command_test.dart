import 'dart:io' show Platform;

import 'package:file/memory.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../mocks/mocks.dart';

const l10nFileContent =
    '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb''';

const arbFileContentSimple =
    '''
{
  "@@locale": "en",
  "a": "a",
  "b": "b",
  "c": "c",
  "d": "d"
}''';

const mainFileContent =
    '''
void main() {
  AppLocalizations.of(context).a;
  AppLocalizations.of(context).a;
  l10n.b;
  Stuff().c;
  context.l10n.d;
}''';

void main() {
  group('check-unused', () {
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

      expect(exitCode, ExitCode.success.code);
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

      expect(exitCode, ExitCode.success.code);
    });
  });
}
