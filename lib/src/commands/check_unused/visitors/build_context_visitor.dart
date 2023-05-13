import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// BuildContextVisitor
class BuildContextVisitor extends RecursiveAstVisitor<void> {
  /// BuildContextVisitor
  BuildContextVisitor({required final String localizationClass})
      : _localizationClass = localizationClass;

  final String _localizationClass;

  /// methodName
  String methodName = '';

  @override
  void visitExtensionDeclaration(final ExtensionDeclaration node) {
    super.visitExtensionDeclaration(node);
    if ((node.extendedType as NamedType).name2.lexeme == 'BuildContext') {
      final methodDeclarationList =
          node.members.whereType<MethodDeclaration>().where(
                (final e) =>
                    (e.returnType as NamedType?)?.name2.lexeme ==
                    _localizationClass,
              );
      if (methodDeclarationList.isEmpty) {
        return;
      }
      methodName = methodDeclarationList.first.name.lexeme;
    }
  }
}
