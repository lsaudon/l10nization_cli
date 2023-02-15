import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends RecursiveAstVisitor<void> {
  /// L10nVisitor
  L10nVisitor(this._value);

  static const _list = [
    'l10n',
    'context.l10n',
    'AppLocalizations.of(context)',
  ];

  final Iterable<String> _value;

  final _invocations = <String>{};

  /// invocations
  Set<String> get invocations => _invocations;

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    if (_value.contains(node.name) &&
        node.parent!.childEntities.any(
          (final e) => _list.contains(e.toString()),
        )) {
      _invocations.add(node.name);
      return;
    }
    return;
  }
}
