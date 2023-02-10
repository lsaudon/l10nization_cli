import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends GeneralizingAstVisitor<void> {
  /// L10nVisitor
  L10nVisitor(this._value);

  final Iterable<String> _value;

  final _invocations = <String>{};

  /// invocations
  Set<String> get invocations => _invocations;

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    if (_value.contains(node.name)) {
      _invocations.add(node.name);
      return;
    }
    return;
  }
}
