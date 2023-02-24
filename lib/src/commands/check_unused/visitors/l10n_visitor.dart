import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class L10nVisitor extends RecursiveAstVisitor<void> {
  /// L10nVisitor
  L10nVisitor({
    required final String localizationClass,
    required final Iterable<String> keys,
    required final String methodName,
  })  : _localizationClass = localizationClass,
        _values = keys.toList(),
        _methodName = methodName;

  final String _localizationClass;
  final List<String> _values;
  final String _methodName;

  /// unusedKeys
  Iterable<String> get unusedKeys => _values;

  @override
  void visitSimpleIdentifier(final SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (!_values.contains(node.name)) {
      return;
    }
    final parent = node.parent;
    if (parent == null) {
      return;
    }
    if (_findL10nValue(parent)) {
      _values.remove(node.name);
    }
  }

  bool _findL10nValue(final AstNode parent) {
    if (parent is PropertyAccess) {
      final realTarget = parent.realTarget;
      if (realTarget is PrefixedIdentifier) {
        return realTarget.name == 'context.$_methodName';
      }
      return _hasLocalizationClass(
        expression: realTarget,
        localizationClass: _localizationClass,
      );
    }
    if (parent is PrefixedIdentifier) {
      final visitor = _Visitor(
        localizationClass: _localizationClass,
        prefix: parent.prefix.name,
      );
      parent.thisOrAncestorOfType<BlockFunctionBody>()?.visitChildren(visitor);
      return visitor.isL10nValue;
    }
    if (_isExtension(parent)) {
      return true;
    }
    return false;
  }

  bool _isExtension(final AstNode parent) =>
      parent.thisOrAncestorMatching(
        (final a) =>
            a is ExtensionDeclaration &&
            (a.extendedType as NamedType).name.name == _localizationClass,
      ) !=
      null;
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor({
    required final String localizationClass,
    required final String prefix,
  })  : _localizationClass = localizationClass,
        _prefix = prefix;

  final String _prefix;
  final String _localizationClass;

  bool isL10nValue = false;

  @override
  void visitVariableDeclaration(final VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (node.name.lexeme == _prefix) {
      final initializer = node.initializer;
      if (initializer == null) {
        return;
      }
      isL10nValue = _hasLocalizationClass(
        expression: initializer,
        localizationClass: _localizationClass,
      );
    }
  }
}

bool _hasLocalizationClass({
  required final Expression expression,
  required final String localizationClass,
}) {
  if (expression is! MethodInvocation) {
    return false;
  } else {
    final target = expression.realTarget;
    return target is SimpleIdentifier && target.name == localizationClass;
  }
}
