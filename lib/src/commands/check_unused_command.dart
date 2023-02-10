import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:l10nization_cli/src/result.dart';
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
      'input',
      abbr: 'i',
      help: 'The path to the yaml file for localisation',
      valueHelp: 'l10n.yaml',
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
    final result = await _getL10nKeys();
    if (result.hasError) {
      return result.exitCode!.code;
    }

    _logger.info(result.value.toString());

    Glob('**.dart')
        .list(root: '${_fileSystem.currentDirectory.path}\\example')
        .where((final file) {
      if (file is! File) {
        return false;
      }
      return !['.dart_tool']
          .any((final excludePattern) => file.path.contains(excludePattern));
    });

    return ExitCode.success.code;
  }

  Future<Result<List<String>>> _getL10nKeys() async {
    if (!argResults!.wasParsed('input')) {
      return Result.error(ExitCode.noInput);
    }

    final l10nYamlFile = p.join(
      _fileSystem.currentDirectory.path,
      argResults!['input'] as String,
    );
    final doc = loadYaml(await _fileSystem.file(l10nYamlFile).readAsString())
        as YamlMap;
    return Result.value(
      (json.decode(
        await _fileSystem
            .file(
              p.join(
                p.dirname(l10nYamlFile),
                '${doc['arb-dir']}/${doc['template-arb-file']}',
              ),
            )
            .readAsString(),
      ) as Map<String, dynamic>)
          .keys
          .where((final e) => !e.startsWith('@'))
          .toList(),
    );
  }
}
