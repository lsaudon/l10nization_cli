import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/commands/sample_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/mocks.dart';

void main() {
  group('sample', () {
    late Logger logger;
    late L10nizationCliCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();
      commandRunner = L10nizationCliCommandRunner(logger: logger);
    });

    test('tells a joke', () async {
      final exitCode = await commandRunner.run([SampleCommand.commandName]);

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info('Which unicorn has a cold? The Achoo-nicorn!'),
      ).called(1);
    });
    test('tells a joke in cyan', () async {
      final exitCode =
          await commandRunner.run([SampleCommand.commandName, '-c']);

      expect(exitCode, ExitCode.success.code);

      verify(
        () => logger.info(
          lightCyan.wrap('Which unicorn has a cold? The Achoo-nicorn!'),
        ),
      ).called(1);
    });

    test('wrong usage', () async {
      final exitCode =
          await commandRunner.run([SampleCommand.commandName, '-p']);

      expect(exitCode, ExitCode.usage.code);

      verify(() => logger.err('Could not find an option or flag "-p".'))
          .called(1);
      verify(
        () => logger.info(
          '''
Usage: $executableName sample [arguments]
-h, --help    Print this usage information.
-c, --cyan    Prints the same joke, but in cyan

Run "$executableName help" to see global options.''',
        ),
      ).called(1);
    });
  });
}
