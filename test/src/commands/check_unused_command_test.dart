import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:file/memory.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/commands.dart';
import 'package:l10nization_cli/src/visitors/l10n_visitor.dart';
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
    "helloWorld": "Hello World"
}''';

const content = '''
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
        body: Text(AppLocalizations.of(context).helloWorld),
      );
}
''';

void main() {
  group('check-unused', () {
    test('When l10n.yaml is right', () async {
      final logger = MockLogger();
      final mfs = MemoryFileSystem.test();

      mfs.file('l10n.yaml')
        ..createSync()
        ..writeAsStringSync(l10nFileContent);

      mfs.file('lib/l10n/arb/app_en.arb')
        ..createSync(recursive: true)
        ..writeAsStringSync(arbFileContentSimple);

      final commandRunner = L10nizationCliCommandRunner(
        logger: logger,
        fileSystem: mfs,
      );
      final exitCode = await commandRunner.run(
        [
          CheckUnusedCommand.commandName,
          '--input',
          'l10n.yaml',
        ],
      );

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('[helloWorld]'),
      ).called(1);
    });

// PropertyAccessImpl (AppLocalizations.of(context).helloWorld)
// MethodInvocationImpl (AppLocalizations.of(context))
// SimpleIdentifierImpl (helloWorld)

    test('hello_parser', () {
      final result = parseString(content: content);
      result.unit.accept(L10nVisitor('helloWorld'));
    });
  });
}
