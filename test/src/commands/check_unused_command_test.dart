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
template-arb-file: app_en.arb''';

const arbFileContentSimple = '''
{
  "@@locale": "en",
  "helloMoon": "Hello Moon",
  "helloWorld": "Hello World",
  "seeingTheWorldAgain": "Seeing the world again"
}''';

const mainFileContent = '''
void main() {
  AppLocalizations.of(context).helloWorld;
  AppLocalizations.of(context).helloWorld;
  l10n.helloMoon;
  Stuff().seeingTheWorldAgain;
}''';

void main() {
  group('check-unused', () {
    test('When l10n.yaml is right', () async {
      final mfs = MemoryFileSystem.test(
        style: Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix,
      );

      <String, String>{
        'lib/l10n/arb/app_en.arb': arbFileContentSimple,
        'lib/main.dart': mainFileContent,
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

      verifyNever(() => logger.info('helloWorld'));
      verifyNever(() => logger.info('helloMoon'));
      verify(() => logger.info('seeingTheWorldAgain')).called(1);

      expect(exitCode, ExitCode.success.code);
    });
  });
}
