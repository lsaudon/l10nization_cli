import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:l10nization_cli/src/command_runner.dart';
import 'package:l10nization_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('L10nizationCliCommandRunner', () {
    late Logger logger;
    late L10nizationCliCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();

      commandRunner = L10nizationCliCommandRunner(logger: logger);
    });

    test('can be instantiated without an explicit analytics/logger instance',
        () {
      final commandRunner = L10nizationCliCommandRunner();
      expect(commandRunner, isNotNull);
      expect(commandRunner, isA<CompletionCommandRunner<int>>());
    });

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((final _) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message));
      verify(() => logger.info(commandRunner.usage));
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((final _) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--version']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message));
      verify(() => logger.info('exception usage'));
    });

    group('--version', () {
      test('outputs current version', () async {
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(() => logger.info(packageVersion));
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await commandRunner.run(['--verbose']);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:'));
        verify(() => logger.detail('  Top level options:'));
        verify(() => logger.detail('  - verbose: true'));
        verifyNever(() => logger.detail('    Command options:'));
      });

      test('enables verbose logging for sub commands', () async {
        final result = await commandRunner.run([
          '--verbose',
          'check-unused',
          'example',
        ]);
        expect(result, equals(ExitCode.success.code));

        verify(() => logger.detail('Argument information:'));
        verify(() => logger.detail('  Top level options:'));
        verify(() => logger.detail('  - verbose: true'));
        verify(() => logger.detail('  Command: check-unused'));
        verify(() => logger.detail('    Command options:'));
      });
    });
  });
}
