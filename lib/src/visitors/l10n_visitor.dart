import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends RecursiveAstVisitor<void> {
  /// L10nVisitor
  L10nVisitor(final Iterable<String> keys) : _values = keys.toList();

  static const _list = [
    'l10n',
    'context.l10n',
    'AppLocalizations.of(context)',
  ];

  final List<String> _values;

  /// unusedKeys
  List<String> get unusedKeys => _values;

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    if (_values.contains(node.name) &&
        node.parent!.childEntities.any(
          (final e) => _list.contains(e.toString()),
        )) {
      _values.remove(node.name);
      return;
    }
  }
}
