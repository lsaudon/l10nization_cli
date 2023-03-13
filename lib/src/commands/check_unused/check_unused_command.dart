import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';
import 'package:l10nization_cli/src/commands/check_unused/visitors/build_context_visitor.dart';
import 'package:l10nization_cli/src/commands/check_unused/visitors/l10n_visitor.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// {@template check_unused_command}
/// `l10nization check-unused`
///
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class CheckUnusedCommand extends Command<int> {
  /// {@macro check_unused_command}
  CheckUnusedCommand({
    required final Logger logger,
    required final FileSystem fileSystem,
  })  : _logger = logger,
        _fileSystem = fileSystem;

  final Logger _logger;
  final FileSystem _fileSystem;

  @override
  String get description => 'Check unused localizations values';

  /// commandName
  static const String commandName = 'check-unused';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final root = _getRoot();
    final list = await _getDartFiles(root);
    const localizationClass = 'AppLocalizations';
    final methodName = await _getMethodNameOfAppLocalizations(
      list: list,
      localizationClass: localizationClass,
    );

    final keys = await _getKeys(root);
    final unusedKeys = await _getUnusedTranslations(
      list: list,
      keys: keys,
      localizationClass: localizationClass,
      methodName: methodName,
    );

    if (unusedKeys.isEmpty) {
      return ExitCode.success.code;
    }

    _logger.info('''

The list of unused translations:
''');
    unusedKeys.forEach(_logger.info);
    _logger.info('');

    return ExitCode.usage.code;
  }

  String _getRoot() => p.join(
        _fileSystem.currentDirectory.path,
        argResults!.rest.isNotEmpty ? argResults?.rest.first : '',
      );

  Future<Iterable<FileSystemEntity>> _getDartFiles(final String root) async =>
      Glob('**.dart')
          .listFileSystem(
        _fileSystem,
        root: root,
        followLinks: false,
      )
          .where((final f) {
        if (f is! File) {
          return false;
        }
        return !['.dart_tool'].any((final e) => f.path.contains(e));
      }).toList();

  Future<Iterable<String>> _getKeys(final String root) async {
    final doc = loadYaml(
      await _fileSystem.file(p.join(root, 'l10n.yaml')).readAsString(),
    ) as YamlMap;
    return (json.decode(
      await _fileSystem
          .file(
            p.join(
              root,
              p.joinAll(p.split(doc['arb-dir'].toString())),
              doc['template-arb-file'].toString(),
            ),
          )
          .readAsString(),
    ) as Map<String, dynamic>)
        .keys
        .where((final e) => !e.startsWith('@'));
  }

  Future<String> _getMethodNameOfAppLocalizations({
    required final Iterable<FileSystemEntity> list,
    required final String localizationClass,
  }) async {
    for (final file in list) {
      final visitor = BuildContextVisitor(localizationClass: localizationClass);
      parseString(content: await _fileSystem.file(file).readAsString())
          .unit
          .visitChildren(visitor);
      if (visitor.methodName.isNotEmpty) {
        return visitor.methodName;
      }
    }
    return '';
  }

  Future<Iterable<String>> _getUnusedTranslations({
    required final Iterable<FileSystemEntity> list,
    required final Iterable<String> keys,
    required final String localizationClass,
    required final String methodName,
  }) async {
    final aKeys = keys.toList();
    for (final file in list) {
      final visitor = L10nVisitor(
        localizationClass: localizationClass,
        keys: aKeys,
        methodName: methodName,
      );
      parseString(content: await _fileSystem.file(file).readAsString())
          .unit
          .visitChildren(visitor);
      aKeys
        ..clear()
        ..addAll(visitor.unusedKeys);
    }
    return aKeys;
  }
}
