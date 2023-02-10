import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends GeneralizingAstVisitor<bool> {
  /// L10nVisitor
  L10nVisitor(this._value);

  final String _value;
  @override
  bool? visitSimpleIdentifier(final SimpleIdentifier node) {
    if (node.name == _value) {
      return true;
    }
    return false;
  }
}
