import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:l10nization_cli/src/result.dart';
import 'package:l10nization_cli/src/visitors/l10n_visitor.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// {@template check_unused_command}
/// `l10nization_cli check-unused`
///
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CheckUnusedCommand extends Command<int> {
  /// {@macro check_unused_command}
  CheckUnusedCommand({
    required final Logger logger,
    required final FileSystem fileSystem,
  })  : _logger = logger,
        _fileSystem = fileSystem {
    argParser.addOption(
      'root',
      abbr: 'r',
      help: 'The path to the root of your project',
      valueHelp: 'my_app',
    );
  }

  @override
  String get description => 'Check unused localizations values';

  /// commandName
  static const String commandName = 'check-unused';

  @override
  String get name => commandName;

  final Logger _logger;
  final FileSystem _fileSystem;

  @override
  Future<int> run() async {
    final root = p.join(
      _fileSystem.currentDirectory.path,
      argResults!['root'] as String? ?? '',
    );

    final result = await _getL10nKeys(root);
    if (result.hasError) {
      return result.exitCode!.code;
    }

    final keys = result.value!;
    final invocations = <String>{};
    for (final file in await _getDartFiles(_fileSystem, root).toList()) {
      final result =
          parseString(content: await _fileSystem.file(file).readAsString());
      final visitor = L10nVisitor(keys);
      result.unit.visitChildren(visitor);
      invocations.addAll(visitor.invocations);
    }
    final unusedKeys = keys.toList();
    invocations.forEach(unusedKeys.remove);
    unusedKeys.forEach(_logger.info);
    _logger.success('Success');

    return ExitCode.success.code;
  }

  Stream<FileSystemEntity> _getDartFiles(
    final FileSystem fileSystem,
    final String root,
  ) =>
      Glob('**.dart').listFileSystem(fileSystem, root: root).where((final f) {
        if (f is! File) {
          return false;
        }
        return !['.dart_tool'].any((final e) => f.path.contains(e));
      });

  Future<Result<Iterable<String>>> _getL10nKeys(final String root) async {
    final doc = loadYaml(
      await _fileSystem
          .file(
            p.join(
              root,
              'l10n.yaml',
            ),
          )
          .readAsString(),
    ) as YamlMap;
    return Result.value(
      (json.decode(
        await _fileSystem
            .file(
              p.join(
                root,
                '${doc['arb-dir']}/${doc['template-arb-file']}',
              ),
            )
            .readAsString(),
      ) as Map<String, dynamic>)
          .keys
          .where((final e) => !e.startsWith('@')),
    );
  }
}
