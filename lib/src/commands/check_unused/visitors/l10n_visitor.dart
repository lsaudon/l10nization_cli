import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends RecursiveAstVisitor<void> {
  /// L10nVisitor
  L10nVisitor(final Iterable<String> keys) : _values = keys.toList();

  final List<String> _values;

  /// unusedKeys
  Iterable<String> get unusedKeys => _values;

  @override
  void visitExtensionDeclaration(final ExtensionDeclaration node) {
    super.visitExtensionDeclaration(node);
    if ((node.extendedType as NamedType).name.name != 'AppLocalizations') {
      return;
    }
    _removeUsedKeys(node);
  }

  @override
  void visitMethodInvocation(final MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.beginToken.lexeme != 'AppLocalizations') {
      return;
    }
    _removeUsedKeys(node);
  }

  @override
  void visitPrefixedIdentifier(final PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);
    if (node.name != 'context.l10n') {
      return;
    }
    _removeUsedKeys(node);
  }

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (node.name != 'l10n') {
      return;
    }
    _removeUsedKeys(node);
  }

  void _removeUsedKeys(final AstNode node) {
    final visitor = _Visitor(_values);
    node.parent?.visitChildren(visitor);
    visitor.usedKeys.forEach(_values.remove);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(final Iterable<String> keys) : _values = keys.toList();

  final List<String> _values;

  /// unusedKeys
  final List<String> usedKeys = <String>[];

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (!_values.contains(node.name)) {
      return;
    }
    usedKeys.add(node.name);
  }
}
